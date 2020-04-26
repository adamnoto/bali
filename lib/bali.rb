require_relative "bali/version"

begin
  require "rails"
  require "rails/generators"
rescue LoadError => e
  # ignores
end

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
generators = "#{__dir__}/generators"
loader.ignore(generators)
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

  require "bali/railtie" if defined? Rails
end

loader.eager_load
