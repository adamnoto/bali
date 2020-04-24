require_relative "bali/version"

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
end

loader.eager_load
