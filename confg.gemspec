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
  spec.homepage      = "https://github.com/guideline-tech/confg"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir["lib/**/*"] + Dir["*.gemspec"]

  spec.executables   = spec.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake"

  spec.required_ruby_version = ">= 3.2.0"
end
