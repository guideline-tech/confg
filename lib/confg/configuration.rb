# frozen_string_literal: true

require "yaml"

module Confg
  class Configuration

    attr_reader :confg_env, :confg_root, :confg_data

    def initialize(env: Confg.env, root: Confg.root)
      @confg_env = env.to_s
      @confg_root = Pathname.new(root)
      @confg_data = {}
    end

    def inspect
      "#<#{self.class.name} #{confg_data.inspect}>"
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
      confg_data.transform_values do |v|
        v.is_a?(self.class) ? v.to_h : v
      end
    end

    def key?(key)
      confg_data.key?(key.to_s)
    end

    def get(key)
      fetch(key) { nil }
    end
    alias [] get

    def fetch(key, &block)
      confg_data.fetch(key.to_s, &block)
    end

    def set(key, value = nil)
      confg_data[key.to_s] = case value
      when ::Hash
        open(key) do |child|
          value.each_pair do |k, v|
            child.set(k, v)
          end
        end
      else
        value
      end
    end
    alias []= set

    def open(key)
      inner = get(key) || spawn_child
      yield(inner)
      set(key, inner)
    end

    def load_key(key,yaml_loader_options = {})
      # loads yaml file with given key
      load_yaml(key, yaml_loader_options, key: key)
    end

    def load_yaml(path, yaml_loader_options = {}, key: nil, ignore_env: false)
      found_path = find_config_yaml(path)

      raise ArgumentError, "#{path} could not be found" if found_path.nil?

      ctxt = ::Confg::ErbContext.new
      raw_content = ::File.read(found_path)
      erb_content = ctxt.evaluate(raw_content)
      yaml_content = ::YAML.safe_load(erb_content, **yaml_loader_options.merge(aliases: true)) # due to shared sections

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

    def method_missing(key, *args, **kwargs, &block)
      key = key.to_s
      return set(key[0...-1], args[0]) if key.end_with?("=")
      return fetch(key) if key?(key)

      begin
        confg_data.send(key, *args, **kwargs, &block)
      rescue NoMethodError => e
        raise KeyError, "Unrecognized key `#{key}`", e.backtrace
      end
    end

    def respond_to_missing?(key, include_private = false)
      key = key.to_s
      return true if key.end_with?("=")
      return true if key?(key)

      confg_data.respond_to?(key, include_private)
    end

    protected

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
