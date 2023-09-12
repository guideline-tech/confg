# frozen_string_literal: true

require "confg/version"
require "confg/configuration"
require "confg/erb_context"

module Confg

  class << self

    def cache
      @cache ||= {}
    end

    def root
      return @root if defined?(@root)

      @root = calc_root_path
    end

    def env
      return @env if defined?(@env)

      @env = calc_env_string
    end

    def erb_function(function_name, &block)
      ::Confg::ErbContext.class_eval do
        define_method(function_name, &block)
      end
      self
    end

    def config(env: self.env, root: self.root)
      config_key = "#{env}--#{root}"
      out = (cache[config_key] ||= ::Confg::Configuration.new(env: env, root: root))
      yield out if block_given?
      out
    end
    alias configure config

    def method_missing(method_name, ...)
      config.send(method_name, ...)
    end

    def respond_to_missing?(...)
      true
    end

    protected

    def calc_root_string
      return Rails.root.to_s if defined?(Rails)
      return RAILS_ROOT      if defined?(RAILS_ROOT)
      return RACK_ROOT       if defined?(RACK_ROOT)

      ENV["RAILS_ROOT"] || ENV["RACK_ROOT"] || Dir.pwd
    end

    def calc_root_path
      ::Pathname.new(calc_root_string).expand_path
    end

    def calc_env_string
      return ::Rails.env.to_s if defined?(::Rails)
      return RAILS_ENV if defined?(RAILS_ENV)
      return RACK_ENV if defined?(RACK_ENV)

      ENV["RAILS_ENV"] || ENV["RACK_ENV"] || nil
    end

    def reset!
      remove_instance_variable("@cache") if defined?(@cache)
      remove_instance_variable("@env") if defined?(@env)
      remove_instance_variable("@root") if defined?(@root)
    end

  end

end
