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
require 'bali'
require 'rspec'
require "pry"
require "bali_spec"

RSpec.configure do |config|
  config.mock_with :rspec

  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end

  config.mock_with :rspec do |c|
    c.syntax = [:should, :expect]
  end

end
