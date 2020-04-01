# frozen_string_literal: true

require "yaml"

module Confg
  class Configuration < ::SimpleDelegator

    attr_reader :confg_env, :confg_root

    def initialize(env: Confg.env, root: Confg.root)
      @confg_env = env.to_s
      @confg_root = Pathname.new(root)

      super({})
    end

    def tmp(key, value)
      initial = get(key)
      set(key, value)
      yield
    ensure
      set(key, initial)
    end

    def merge(other)
      other.each_pair do |k, v|
        set(k, v)
      end
    end
    alias merge! merge

    def to_h
      __getobj__.transform_values do |v|
        v.is_a?(self.class) ? v.to_h : v
      end
    end

    def get(key)
      __getobj__[key.to_s]
    end
    alias [] get

    def get!(key)
      __getobj__.fetch(key.to_s)
    end

    def set(key, value = nil)
      __getobj__[key.to_s] = case value
      when ::Hash
        set_block(key) do |child|
          value.each_pair do |k, v|
            child.set(k, v)
          end
        end
      else
        value
      end
    end
    alias []= set

    def load_key(key)
      # loads yaml file with given key
      load_yaml(key, key: key)
    end

    def load_yaml(path, key: nil, ignore_env: false)
      found_path = find_config_yaml(path)

      raise ArgumentError, "#{path} could not be found" if found_path.nil?

      ctxt = ::Confg::ErbContext.new
      raw_content = ::File.read(found_path)
      erb_content = ctxt.evaluate(raw_content)
      yaml_content = ::YAML.send :load, erb_content

      unless ignore_env
        yaml_content = yaml_content[confg_env] if confg_env && yaml_content.is_a?(::Hash) && yaml_content.key?(confg_env)
      end

      if key
        set(key, yaml_content)
      else
        if yaml_content.is_a?(Array)
          raise "A key must be provided to load the file at: #{found_path}"
        else
          yaml_content.each do |k, v|
            set(k, v)
          end
        end
      end
    end
    alias load_yml load_yaml

    def method_missing(method_name, *args, &block)
      key = method_name.to_s

      if __getobj__.respond_to?(key)
        super
      elsif key.end_with?("=") && !args.empty?
        set(key[0...-1], args[0])
      elsif block_given?
        set_block(key, &block)
      else
        get!(key)
      end
    end

    def respond_to_missing?(*_args)
      true
    end

    protected

    def set_block(key)
      inner = get(key) || spawn_child
      yield(inner)
      set(key, inner)
    end

    def find_config_yaml(path)
      path = path.to_s
      # give it back if it starts with a slash
      if path.start_with?("/")
        return nil unless ::File.file?(path)

        return path
      end

      to_try = []
      unless path.end_with?(".yml")
        to_try << confg_root.join("config/#{path}.yml")
      end
      to_try << confg_root.join("config/#{path}")
      to_try << confg_root.join(path)

      to_try.each do |file|
        return file.to_s if File.file?(file)
      end

      nil
    end

    def spawn_child
      self.class.new(env: confg_env, root: confg_root)
    end

  end
end
