# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bali/version'

Gem::Specification.new do |spec|
  spec.name          = "bali"
  spec.version       = Bali::VERSION
  spec.authors       = ["Adam Pahlevi"]
  spec.email         = ["adam.pahlevi@gmail.com"]

  spec.summary       = %q{Bali is the Ruby language authorization library}
  spec.description   = %q{Bali (Bulwark Authorizer Library) is a simple to use Ruby authorization library, it can be used within your Rails project, or Sinatra, or plain Ruby files. It does not assume you to use specific Ruby library/gem/framework, just pure Ruby and you can still use it.}
  spec.homepage      = "https://github.com/saveav/bali"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
