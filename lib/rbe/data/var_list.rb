require 'yaml'
require 'readline'

module Rbe::Data
  class VarList
    attr_accessor :save_local

    def initialize
      @save_local = false
      load_vars
      load_local_vars
    end

    def temp_vars
      @temp_vars ||= {}
    end

    def load_local_vars
      @local_vars = File.exist?('vars.rbe.yaml') ? YAML::load_file('vars.rbe.yaml') : {}
    end

    def save_local_vars
      IO.write('vars.rbe.yaml', @local_vars.to_yaml)
    end

    def load_vars
      @vars = File.exist?(File.expand_path('~/vars.rbe.yaml')) ? YAML::load_file(File.expand_path('~/vars.rbe.yaml')) : {}
    end

    def save_vars
      IO.write(File.expand_path('~/vars.rbe.yaml'), @vars.to_yaml)
    end

    def get(var_name, prompt_if_missing_required = false)
      required = var_name[0] == '#'
      var_name = var_name[1..-1] if required
      if self.temp_vars.has_key?(var_name)
        self.temp_vars[var_name]
      elsif has_key?(var_name)
        self[var_name]
      elsif required && prompt_if_missing_required
        # puts "missing required variable '#{var_name}'"
        # print "#{var_name} (press ENTER to cancel): "
        v = Readline.readline("#{var_name} (press ENTER to cancel): ")
        if v.nil? || v.empty?
          exit 1
        else
          self.temp_vars[var_name] = v
          get("##{var_name}", true)
        end
      elsif required
        "{{##{var_name}}}"
      else
        nil
      end
    end

    def [](var_name)
      @local_vars.has_key?(var_name) ? @local_vars[var_name] : @vars[var_name]
    end

    def []=(var_name, value)
      if save_local
        @local_vars[var_name] = value
        save_local_vars
      else
        @vars[var_name] = value
        save_vars
      end
    end

    def has_key?(var_name)
      @local_vars.has_key?(var_name) || @vars.has_key?(var_name)
    end

    def keys
      (@local_vars.keys + @vars.keys).uniq
    end

    def delete(var_name)
      if save_local
        @local_vars.delete(var_name)
        save_local_vars
      else
        @vars.delete(var_name)
        save_vars
      end
    end

    protected :load_vars, :save_vars, :load_local_vars, :save_local_vars
  end
end