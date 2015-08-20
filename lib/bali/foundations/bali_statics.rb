module Bali
  extend self

  def rule_classes
    Bali::RULE_CLASS_MAP
  end

  def rule_class_for(target)
    if target.is_a?(Symbol)
      class_name = Bali::ALIASED_RULE_CLASS_MAP[target]
      return class_name.nil? ? nil : rule_class_for(class_name)
    else
      raise Bali::DslError, "Target must be a class" unless target.is_a?(Class)
      rule_class = Bali::RULE_CLASS_MAP[target.to_s]
      return rule_class.nil? ? nil : rule_class
    end
  end

  # attempt to search the rule group, but if not exist, will return nil
  def rule_group_for(target_class, subtarget)
    rule_class = Bali.rule_class_for(target_class)
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
      alias_target = rule_class.alias_name

      raise Bali::DslError, "Target must be a class" unless target.is_a?(Class)

      # remove any previous association of rule
      begin 
        last_associated_alias = Bali::REVERSE_ALIASED_RULE_CLASS_MAP[target]
        if last_associated_alias
          Bali::ALIASED_RULE_CLASS_MAP.delete(last_associated_alias)
          Bali::REVERSE_ALIASED_RULE_CLASS_MAP.delete(target)
          Bali::RULE_CLASS_MAP.delete(target)
        end
      end

      # if "as" is present
      if alias_target.is_a?(Symbol)
        Bali::ALIASED_RULE_CLASS_MAP[alias_target] = target
        Bali::REVERSE_ALIASED_RULE_CLASS_MAP[target] = alias_target
      end

      Bali::RULE_CLASS_MAP[target.to_s] = rule_class
      rule_class
    else
      raise Bali::DslError, "Only allow instance of Bali::RuleClass"
    end
  end # add_rule_class
end
