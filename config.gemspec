# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'conf/version'

Gem::Specification.new do |gem|
  gem.name          = "conf"
  gem.version       = Conf::VERSION
  gem.authors       = ["Mike Nelson"]
  gem.email         = ["mike@mnelson.io"]
  gem.description   = %q{Config the pipes}
  gem.summary       = %q{Sets shared variables for applications}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'activesupport'
end
