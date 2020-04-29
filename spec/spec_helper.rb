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
require "pry"
require "test_app/app"
require 'rspec/rails'

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
