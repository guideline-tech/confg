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

  def test_set_path_sets_top_level_value
    config.set_path("foo", "bar")
    assert_equal "bar", config.foo
  end

  def test_set_path_sets_nested_value
    config.set_path("database.host", "localhost")
    assert_equal "localhost", config.database.host
  end

  def test_set_path_sets_deeply_nested_value
    config.set_path("api.keys.google", "xyz123")
    assert_equal "xyz123", config.api.keys.google
  end

  def test_get_path_retrieves_nested_value
    config.set_path("database.host", "localhost")
    assert_equal "localhost", config.get_path("database.host")
  end

  def test_get_path_returns_nil_for_missing_path
    assert_nil config.get_path("missing.path")
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

end
