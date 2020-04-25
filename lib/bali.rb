require_relative "bali/version"

begin
  require "rails"
rescue LoadError => e
  # ignores
end

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
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
end

loader.eager_load
