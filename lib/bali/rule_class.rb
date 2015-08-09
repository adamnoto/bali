# the parent of all Bali::RuleGroup.
class Bali::RuleClass
  attr_reader :target_class
  attr_accessor :alias_name

  attr_accessor :rule_groups

  def initialize(target_class)
    if target_class.is_a?(Class)
      @target_class = target_class
    else
      raise Bali::DslError, "Target class must be a Class"
    end

    self.rule_groups = {}
  end

  def add_rule_group(rule_group)
    if rule_group.is_a?(Bali::RuleGroup)
      target_user = rule_group.subtarget
      self.rule_groups[target_user.to_sym] = rule_group
    else
      raise Bali::DslError, "Rule group must be an instance of Bali::RuleGroup"
    end
  end

  def rules_for(target_user)
    self.rule_groups[target_user.to_sym]
  end
end
