# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ejabberd_rest/version'

Gem::Specification.new do |spec|
  spec.name          = "ejabberd_rest"
  spec.version       = EjabberdRest::VERSION
  spec.authors       = ["Fajar Budiprasetyo"]
  spec.email         = ["fajar.ab@gmail.com"]
  spec.summary       = %q{Ruby interface for ejabberd mod_rest.}
  spec.description   = %q{Ruby interface to add and delete user using ejabberd mod_rest.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"

  spec.add_runtime_dependency "faraday", "~> 0.9.0"
end
