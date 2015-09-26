require_relative "bali/version"

# load the DSL syntax maker definition, ordered by proper order of invocation
require_relative "bali/dsl/map_rules_dsl"
require_relative "bali/dsl/rules_for_dsl"

require_relative "bali/objector"
require_relative "bali/printer"

require_relative "bali/foundations/all_foundations"
require_relative "bali/integrators/all_integrators"

module Bali
  # mapping class to a RuleClass
  RULE_CLASS_MAP = {}

  # {
  #   User: :roles,
  #   AdminUser: :admin_roles
  # }
  TRANSLATED_SUBTARGET_ROLES = {}

  # pub/sub for plugin that extend bali
  LISTENABLE_EVENTS = {}
end

module Bali
  extend self
  def map_rules(&block)
    dsl_map_rules = Bali::MapRulesDsl.new
    dsl_map_rules.instance_eval(&block)
  end

  def clear_rules
    Bali::RULE_CLASS_MAP.clear
    true
  end
end
