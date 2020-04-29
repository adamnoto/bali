$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

# try to load simplecov
begin
  require "simplecov"
  if defined?(SimpleCov)
    SimpleCov.start
  end
rescue LoadError => e
  # ignores
end

require "bundler/setup"
require "bali"
require "rspec"
require "pry"
require "bali_spec"

def expect_can operation
  expect(subject.can?(user, operation)).to be_truthy
end

def expect_cant operation
  expect(subject.can?(user, operation)).to be_falsey
end
