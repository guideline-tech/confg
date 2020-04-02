# Confg

Provides a utility for loading and managing configurations for your ruby project.

## Usage

Set specific keys:

    Confg.configure do |c|
      c.foo_setting = 100
      c.bar_setting = "yes"
    end

Supports nesting:

    Confg.configure do |c|
      c.api_keys do |a|
        a.google = 'xyz'
        a.mixpanel = 'abc'
      end
    end

Load a yaml file:

    Confg.configure do |c|
      c.load_yaml "/path/to/file.yml"
    end

Yaml files can be namespaced by environment and contain ERB.

    ---
      development:
        thing: <%= ENV["THING"] %>
      staging:
        thing: 'set value'

Use the values:

    Confg.foo_setting
    #=> 100

    Confg.api_keys
    #=> #<Confg::Configuration { "google" => "xyz", "mixpanel" => "abc" }>

    Confg.api_keys.google # => "xyz"'

    Confg.api_keys.to_h
    #=> { "google" => "xyz", "mixpanel" => "abc" }

    Confg.missing_key
    #=> raises KeyError

    Conf[:missing_key]
    #=> nil
