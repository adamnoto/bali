# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bali/version'

Gem::Specification.new do |spec|
  spec.name          = "bali"
  spec.version       = Bali::VERSION
  spec.authors       = ["Adam Notodikromo"]
  spec.email         = ["abaihaqi@acm.org"]

  spec.summary       = %q{A to-the-point authorization library for Rails}
  spec.description   = %q{Bali (Bulwark Authorization Library) is a to-the-point authorization library for Rails.}
  spec.homepage      = "https://github.com/adamnoto/bali"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|plugins)/}) }
  spec.files         = spec.files.reject { |f| f.match(/\.md|\.txt/i) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "zeitwerk", "~> 2", ">= 2.2"
  spec.add_development_dependency "rails", ">= 5.0.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.9"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "simplecov", "0.17"
  spec.add_development_dependency 'sqlite3'
end
