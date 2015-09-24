# the parent of all Bali::RuleGroup.
class Bali::RuleClass
  attr_reader :target_class

  attr_accessor :rule_groups
  
  # rule group for "other" subtargets, always checked the last time
  # after the "more proper" rule groups are checked
  attr_accessor :others_rule_group

  def initialize(target_class)
    if target_class.is_a?(Class)
      @target_class = target_class
    else
      raise Bali::DslError, "Target class must be a Class"
    end

    self.rule_groups = {}
    self.others_rule_group = Bali::RuleGroup.new(target_class, "__*__")
  end

  def add_rule_group(rule_group)
    if rule_group.is_a?(Bali::RuleGroup)
      target_user = rule_group.subtarget
      if target_user == "__*__" || target_user == :"__*__"
        raise Bali::DslError, "__*__ is a reserved subtarget used by Bali's internal"
      end
      self.rule_groups[Bali::RuleGroup.canon_name(target_user)] = rule_group
    else
      raise Bali::DslError, "Rule group must be an instance of Bali::RuleGroup"
    end
  end

  def rules_for(subtarget)
    return others_rule_group if subtarget == "__*__"
    subtarget = Bali::RuleGroup.canon_name(subtarget)
    self.rule_groups[subtarget]
  end
end
