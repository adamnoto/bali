require_relative "bali/version"

begin
  require "rails"
  require "rails/generators"
rescue LoadError => e
  # ignores
end

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/generators")
loader.ignore("#{__dir__}/bali/rails")
loader.ignore("#{__dir__}/bali/rspec")
loader.setup

module Bali
  extend self

  def config
    @config ||= Bali::Config.new
  end

  def configure
    yield config
  end

  if defined? Rails
    require "bali/railtie"
    require "bali/rails/action_controller"
    require "bali/rails/action_view"
    require "bali/rails/active_record"
  end

  if defined? RSpec
    begin
      require "rspec/matchers"
      require "bali/rspec/able_to_matcher"
    rescue LoadError => e
    end
  end
end

loader.eager_load
