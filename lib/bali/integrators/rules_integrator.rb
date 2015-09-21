module Bali::Integrators::Rule
  extend self

  def rule_classes
    Bali::RULE_CLASS_MAP
  end

  def rule_class_for(target)
    raise Bali::DslError, "Target must be a class" unless target.is_a?(Class)
    rule_class = Bali::RULE_CLASS_MAP[target.to_s]
    return rule_class.nil? ? nil : rule_class
  end

  # attempt to search the rule group, but if not exist, will return nil
  def rule_group_for(target_class, subtarget)
    rule_class = rule_class_for(target_class)
    if rule_class
      rule_group = rule_class.rules_for(subtarget)
      return rule_group
    else
      return nil
    end
  end

  def add_rule_class(rule_class)
    if rule_class.is_a?(Bali::RuleClass)
      target = rule_class.target_class

      raise Bali::DslError, "Target must be a class" unless target.is_a?(Class)

      Bali::RULE_CLASS_MAP[target.to_s] = rule_class
      rule_class
    else
      raise Bali::DslError, "Only allow instance of Bali::RuleClass"
    end
  end # add_rule_class
end
