# frozen_string_literal: true

require "test_helper"

class ConfgTest < Minitest::Test

  def config
    @config ||= ::Confg::Configuration.new(root: __dir__, env: "test")
  end

  def test_simple_keys_can_be_assigned
    config.foo = "bar"
    assert_equal "bar", config.foo
    assert_equal({ "foo" => "bar" }, config.to_h)
  end

  def test_a_child_block_can_be_opened
    config.open :foo do |child|
      child.bar = "baz"
    end

    assert_equal "baz", config.foo.bar
    assert_equal({ "foo" => { "bar" => "baz" } }, config.to_h)
  end

  def test_a_child_block_can_be_merged_by_assigning_a_hash
    config.foo = { "bar" => "baz" }
    assert_equal "baz", config.foo.bar
    assert_equal({ "foo" => { "bar" => "baz" } }, config.to_h)
  end

  def test_an_error_is_raised_for_a_missing_key
    assert_raises KeyError do
      config.foo
    end
  end

  def test_hash_methods_are_accessible
    config.foo = "foo_value"
    config.bar = "bar_value"

    assert_equal(%w[foo bar], config.keys)
    assert_equal(%w[foo_value bar_value], config.values)

    ikeys = []
    config.each_key { |k| ikeys << k }
    assert_equal(%w[foo bar], ikeys)

    ivalues = []
    config.each_value { |v| ivalues << v }
    assert_equal(%w[foo_value bar_value], ivalues)
  end

  def test_a_yml_file_can_be_loaded_by_env
    config.load_yaml("example.yml")
    assert_equal({ "foo" => "foo", "env_setting" => "setting_test" }, config.to_h)
  end

  def test_a_yml_file_can_be_loaded_by_raw
    config.load_yaml("example.yml", ignore_env: true)
    assert_equal({
      "shared" => { "foo" => "foo" },
      "production" => { "env_setting" => "setting_prod", "foo" => "foo" },
      "test" => { "env_setting" => "setting_test", "foo" => "foo" },
    }, config.to_h)
  end

  def test_a_yml_file_doesnt_load_with_additional_permitted_classes
    assert_raises "Psych::DisallowedClass: Tried to load unspecified class: Symbol" do
      config.load_yaml("example_with_symbols.yml", ignore_env: true)
    end
  end

  def test_a_yml_file_can_be_loaded_with_additional_permitted_classes
    config.load_yaml("example_with_symbols.yml", { permitted_classes: [Symbol] }, ignore_env: true)
    assert_equal({
      "shared" => { "foo" => :foo },
      "production" => { "env_setting" => :setting_prod, "foo" => :foo },
      "test" => { "env_setting" => :setting_test, "foo" => :foo },
    }, config.to_h)
  end

  def test_top_level_configs_are_cached_in_root_namespace
    ::Confg.send :reset!
    assert_equal({}, ::Confg.cache)

    default_config = ::Confg.config(env: "test", root: "/")
    custom_config = ::Confg.config(env: "foobar", root: "/Users/x/")

    refute_equal default_config.object_id, custom_config.object_id
    assert_equal 2, ::Confg.cache.size
    assert_equal %w[test--/ foobar--/Users/x/], ::Confg.cache.keys
  end

  def test_load_env_applies_env_vars
    ENV["CONFG_DATABASE__HOST"] = "envhost"
    ENV["CONFG_DATABASE__PORT"] = "5432"

    config.load_env

    assert_equal "envhost", config.database.host
    assert_equal "5432", config.database.port
  ensure
    ENV.delete("CONFG_DATABASE__HOST")
    ENV.delete("CONFG_DATABASE__PORT")
  end

  def test_load_env_with_custom_prefix
    ENV["MYAPP_API__KEY"] = "secret"

    config.load_env(prefix: "MYAPP_")

    assert_equal "secret", config.api.key
  ensure
    ENV.delete("MYAPP_API__KEY")
  end

  def test_load_env_ignores_unrelated_vars
    ENV["OTHER_VAR"] = "ignored"

    config.load_env

    assert_raises(KeyError) { config.other_var }
  ensure
    ENV.delete("OTHER_VAR")
  end

  def test_load_env_deeply_nested
    ENV["CONFG_API__KEYS__GOOGLE"] = "xyz123"

    config.load_env

    assert_equal "xyz123", config.api.keys.google
  ensure
    ENV.delete("CONFG_API__KEYS__GOOGLE")
  end

  def test_load_env_preserves_existing_yaml_config
    # Load YAML config first (has foo and env_setting)
    config.load_yaml("example.yml")
    assert_equal "foo", config.foo
    assert_equal "setting_test", config.env_setting

    # Override only one key via ENV
    ENV["CONFG_FOO"] = "overridden_foo"
    config.load_env

    # foo should be overridden, env_setting should be preserved
    assert_equal "overridden_foo", config.foo
    assert_equal "setting_test", config.env_setting
  ensure
    ENV.delete("CONFG_FOO")
  end

  def test_load_env_preserves_nested_sibling_keys
    # Set up existing nested config
    config.set("database", { "host" => "yaml_host", "port" => "5432", "name" => "mydb" })

    # Override only host via ENV
    ENV["CONFG_DATABASE__HOST"] = "env_host"
    config.load_env

    # host overridden, port and name preserved
    assert_equal "env_host", config.database.host
    assert_equal "5432", config.database.port
    assert_equal "mydb", config.database.name
  ensure
    ENV.delete("CONFG_DATABASE__HOST")
  end

  def test_merge_preserves_sibling_keys_at_nested_level
    # Set up existing nested config
    config.set("database", { "host" => "original_host", "port" => "5432" })

    # Merge only overrides one key
    config.merge({ "database" => { "host" => "new_host" } })

    # Both keys should exist - port should NOT be clobbered
    assert_equal "new_host", config.database.host
    assert_equal "5432", config.database.port
  end

  def test_merge_preserves_deeply_nested_sibling_keys
    # Set up existing deeply nested config
    config.set("api", { "keys" => { "google" => "g123", "stripe" => "s456" } })

    # Merge only overrides one nested key
    config.merge({ "api" => { "keys" => { "google" => "new_google_key" } } })

    # stripe should NOT be clobbered
    assert_equal "new_google_key", config.api.keys.google
    assert_equal "s456", config.api.keys.stripe
  end

end
