module Bali::Integrator::RuleGroup
  extend self

  # attempt to search the rule group,
  # but if not exist, will return nil
  def for(target_class, subtarget)
    rule_class = Bali::Integrator::RuleClass.for(target_class)
    rule_class.nil? ? nil : rule_class.rules_for(subtarget)
  end
end
