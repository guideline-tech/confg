require 'active_support/core_ext/module/delegation'

module Confg
  class Configuration

    delegate :each, :inspect, :to => :@attributes

    def initialize(raise_error_on_miss = false, parent = nil)
      @attributes           = {}
      @raise_error_on_miss  = raise_error_on_miss
      @parent               = parent
    end

    def merge(hash)
      hash.each do |k,v|
        self.set(k,v)
      end
    end
    alias_method :merge!, :merge

    def to_hash
      out = @attributes.to_h.dup
      out.each_pair do |k,v|
        out[k] = v.to_hash if v.is_a?(self.class)
      end
      out
    end
    alias_method :to_h, :to_hash

    def [](key)
      self.get(key)
    end

    def []=(key, value)
      self.set(key, value)
    end

    def tmp(key, value)
      initial = self[key]
      self[key] = value
      yield
    ensure
      self[key] = initial
    end

    def load_key(key)
      # loads yaml file with given key
      load_yaml(key, key: key)
    end

    def load_yaml(path, key: nil, ignore_env: false)
      path = find_config_yaml(path)
      raw_content = File.open(path, 'r'){|io| io.read } rescue nil

      return unless raw_content

      ctxt = ::Confg::ErbContext.new
      content = ctxt.evaluate(raw_content)

      unless ignore_env
        env = defined?(Rails) ? Rails.env.to_s : ENV["RAILS_ENV"] || ENV["RACK_ENV"]
        content = content[Rails.env] if env && content.is_a?(::Hash) && content.has_key?(Rails.env)
      end

      if key
        self.set(key, content)
      else
        if content.is_a?(Array)
          raise "A key must be provided to load the file at: #{path}"
        else
          content.each do |k,v|
            self.set(k, v)
          end
        end
      end
    end
    alias_method :load_yml, :load_yaml

    def method_missing(method_name, *args, &block)
      if method_name.to_s =~ /^(.+)=$/ && !args.empty?
        self.set($1, args.first)
      elsif method_name.to_s =~ /^([^=]+)$/
        if block_given?
          self.set_block($1, &block)
        elsif @attributes.respond_to?($1)
          @attributes.send($1, *args)
        else
          self.get($1)
        end
      else
        super
      end
    end

    def respond_to?(method_name, include_private = false)
      true
    end

    protected

    def set(key, value = nil)
      case value
      when ::Hash
        set_block key do |inner|
          value.each do |k,v|
            inner.set(k, v)
          end
        end
      else
        @attributes[key.to_s] = value
      end
    end

    def get(key)
      if @attributes.has_key?(key.to_s)
        @attributes[key.to_s]
      else
        get_missing_key(key.to_s)
      end
    end

    def get_missing_key(key)
      if @raise_error_on_miss
        raise "Missing key: #{key} in #{@attributes.inspect}"
      else
        nil
      end
    end

    def set_block(key, &block)
      inner = @attributes[key.to_s] || child_new
      block.call(inner)
      set(key, inner)
    end

    def find_config_yaml(path)
      path = path.to_s
      # give it back if it starts with a slash
      return path if path =~ /^\//

      to_try = []
      unless path =~ /.yml$/
        to_try << Confg.root.join("config/#{path}.yml")
      end
      to_try << Confg.root.join("config/#{path}")
      to_try << Confg.root.join(path)

      to_try.each do |file|
        return file if File.file?(file)
      end

      to_try.first
    end

    def child_class
      # same as ours
      self.class
    end

    def child_raise_error_on_miss
      # same as ours
      @raise_error_on_miss
    end

    def child_new
      child_class.new(child_raise_error_on_miss, self)
    end

  end
end
