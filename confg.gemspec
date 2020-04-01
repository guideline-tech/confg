# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "confg/version"

Gem::Specification.new do |spec|
  spec.name          = "confg"
  spec.version       = Confg::VERSION
  spec.authors       = ["Mike Nelson"]
  spec.email         = ["mike@mnelson.io"]
  spec.description   = "Config the pipes"
  spec.summary       = "Sets shared variables for applications"
  spec.homepage      = ""

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 10.0"
end
