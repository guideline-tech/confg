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

  def test_top_level_configs_are_cached_in_root_namespace
    ::Confg.send :reset!
    assert_equal({}, ::Confg.cache)

    default_config = ::Confg.config(env: "test", root: "/")
    custom_config = ::Confg.config(env: "foobar", root: "/Users/x/")

    refute_equal default_config.object_id, custom_config.object_id
    assert_equal 2, ::Confg.cache.size
    assert_equal %w[test--/ foobar--/Users/x/], ::Confg.cache.keys
  end

end
