require 'rbe/data/data_store'

require 'everyday_thor_util/builder'
include EverydayThorUtil::Builder

global.helpers[:clean_cmd] =->(cmd_id) {
  cmd_id.gsub(/(_(nsl|sl|s|rs|loop))+/, '')
}

global.helpers[:print_cmd] =->(sudo, cmd, cmd_args, args) {
  arr = array_to_args(cmd_args, args)
  puts "> #{sudo.nil? ? '' : "#{sudo} "}#{clean_cmd(cmd)} #{arr.join(' ')}"
}

global.helpers[:build_command_name] =->(c, s, sl) {
  "#{c}#{s.nil? ? '' : (s == 'rvmsudo' ? '_rs' : '_s')}#{sl.nil? ? '' : (sl ? '_sl' : '_nsl')}"
}

global.helpers[:print_list] =->(cmd_id, indent = 0, lc = false) {
  cmd_id = cmd_id && subs_vars([cmd_id], [], true).first.first
  if lc
    cmds = []
    cmds << cmd_id if Rbe::Data::DataStore.command(cmd_id)
  else
    cmds = Rbe::Data::DataStore.commands.keys
    cmds = cmds.grep(/.*#{cmd_id}.*/) if cmd_id
    cmds.sort!
  end
  if cmds.nil? || cmds.empty?
    puts "#{' ' * indent}Did not find any commands matching #{cmd_id}"
  else
    longest_cmd = lc || cmds.map { |v| clean_cmd(v.to_s).length }.max
    cmds.each { |cmd|
      info = Rbe::Data::DataStore.command(cmd)
      Rbe::Data::DataStore.vars.push_temp
      register_temp_vars(info.vars)
      if info.command.is_a?(Array)
        puts "#{' ' * indent}#{clean_cmd(cmd.to_s).ljust(longest_cmd + 2)}=> [\n"
        lc2 = info.command.map { |v| clean_cmd(v.to_s).length }.max
        info.command.each { |cmd2| print_list(build_command_name(cmd2, info.sudo, info.silent), indent + longest_cmd + 7, lc2) }
        puts "#{' ' * indent}#{' ' * (longest_cmd + 4)} ]"
      else
        puts "#{' ' * indent}#{clean_cmd(cmd.to_s).ljust(longest_cmd + 2)}=> #{info.silent ? '(silent) ' : ''}#{info.sudo.nil? ? '' : "#{info.sudo} "}#{subs_vars([info.command], [], true).first.first} #{array_to_args(info.args, []).join(' ')}"
      end
      Rbe::Data::DataStore.vars.pop_temp
    }
  end
}