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

  def map_rules(&block)
    dsl_map_rules = Bali::Dsl::MapRulesDsl.new
    dsl_map_rules.instance_eval(&block)
  end

  def clear_rules
    Bali::RULE_CLASS_MAP.clear
    true
  end

  def config
    @config ||= Bali::Config.new
  end

  def configure
    yield config
  end
end

loader.eager_load
