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
loader.ignore("#{__dir__}/bali/activerecord.rb")
loader.setup

module Bali
  # mapping class to a RuleClass
  RULE_CLASS_MAP = {}

  # {
  #   User: :roles,
  #   AdminUser: :admin_roles
  # }
  TRANSLATED_SUBTARGET_ROLES = {}

  extend self

  def config
    @config ||= Bali::Config.new
  end

  def configure
    yield config
  end

  if defined? Rails
    require "bali/railtie"
    require "bali/activerecord"
  end
end

loader.eager_load
