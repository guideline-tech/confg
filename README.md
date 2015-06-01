# Conf

This allows the Conf namespace to provide configuration information

## Usage

    Conf.configure do |c|
      c.app_key = 'core'
      c.app_name = 'core'
    end

Feel free to nest as well

    Conf.configure do |c|
      c.api_keys do |a|
        a.google_places = 'xyz'
        a.mixpanel = 'abc'
      end
    end

Wanna use yaml files? Cool:

    Conf.configure do |c|
      c.load_yaml 'file.yml'
      c.load_yaml :core
      c.load_yaml '/path/to/some.yml', :something
    end

file.yml and core.yml above will be looked for in the Conf.config_dir (which can also be set but defualts to root/config)
Yaml files can be namespaced by environment as well. Oh, and they can have ERB:

    ---
      development:
        thing: <%= ENV["THING"] %>
      staging:
        thing: 'set value'

Ok, using the values:

    Conf.app_key
      # => 'core'
    Conf.api_keys
     # => #<Config::Configuration:0x007f9655e5ba58 @attributes={"google_places"=>"xyz", "mixpanel"=>"abc"} >
    Conf.api_keys.google_places
      # => 'xyz'
