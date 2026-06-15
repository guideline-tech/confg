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
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  github_uri = "https://github.com/guideline-tech/confg"

  spec.homepage = github_uri
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = github_uri
  spec.metadata["changelog_uri"] = "#{github_uri}/releases"
  spec.metadata["github_repo"] = github_uri
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*"] + Dir["*.gemspec"]

  spec.executables   = spec.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "minitest", "~> 6.0"
  spec.add_development_dependency "rake"
end
