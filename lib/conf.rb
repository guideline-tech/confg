require 'conf/version'
require 'conf/configuration'

module Conf

  DEFAULT_OPTS = {
    raise_error_on_miss: false,
    env: nil,
  }.freeze

  class << self

    def root
      @root ||= Pathname.new(calc_root_string).expand_path
    end

    def configure(opts = {})
      opts = DEFAULT_OPTS.merge(opts)

      @configuration ||= ::Conf::Configuration.new(opts[:raise_error_on_miss], opts[:env])
      yield @configuration if block_given?
      @configuration
    end
    alias_method :config, :configure

    def method_missing(method_name, *args, &block)
      config.send(method_name, *args, &block)
    end

    def respond_to_missing?(*args)
      true
    end

    def get(path)
      thing = self
      path.split('.').each do |piece|
        thing = thing.try(piece)
      end
      thing
    end

    protected

    def calc_root_string
      return Rails.root.to_s if defined?(Rails)
      return RAILS_ROOT      if defined?(RAILS_ROOT)
      return RACK_ROOT       if defined?(RACK_ROOT)

      ENV['RAILS_ROOT'] || ENV['RACK_ROOT'] || Dir.pwd
    end

    def reset!
      remove_instance_variable("@configuration")  if defined?(@configuration)
      remove_instance_variable("@root")  if defined?(@root)
    end
  end

end
