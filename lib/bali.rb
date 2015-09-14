require_relative "bali/version"

# load the DSL syntax maker definition, ordered by proper order of invocation
require_relative "bali/dsl/map_rules_dsl"
require_relative "bali/dsl/rules_for_dsl"

require_relative "bali/objector"

require_relative "bali/foundations/all_foundations"
require_relative "bali/integrators/all_integrators"

module Bali
  # mapping class to a RuleClass
  RULE_CLASS_MAP = {}

  # from symbol to full class name
  ALIASED_RULE_CLASS_MAP = {}

  # from full class name to symbol
  REVERSE_ALIASED_RULE_CLASS_MAP = {}

  # {
  #   User: :roles,
  #   AdminUser: :admin_roles
  # }
  TRANSLATED_SUBTARGET_ROLES = {}
end

module Bali
  extend self
  def map_rules(&block)
    dsl_map_rules = Bali::MapRulesDsl.new
    dsl_map_rules.instance_eval(&block)
  end

  def clear_rules
    Bali::RULE_CLASS_MAP.clear
    Bali::REVERSE_ALIASED_RULE_CLASS_MAP.clear
    Bali::ALIASED_RULE_CLASS_MAP.clear
    true
  end
end
