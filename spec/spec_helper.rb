$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require "bundler/setup"
require 'bali'
require 'rspec'

RSpec.configure do |config|
  config.mock_with :rspec

  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end

  config.mock_with :rspec do |c|
    c.syntax = [:should, :expect]
  end

end
