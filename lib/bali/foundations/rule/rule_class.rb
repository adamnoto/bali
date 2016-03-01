# the parent of all Bali::RuleGroup.
class Bali::RuleClass
  attr_reader :target_class

  # consist of canonised subtarget and its rule group, eg: 
  # {
  #   general_user: RuleGroup
  # }
  attr_accessor :rule_groups
  
  # rule group for "other" subtargets, always checked the last time
  # after the "more proper" rule groups are checked
  attr_accessor :others_rule_group

  def initialize(target_class)
    @target_class = target_class
    self.rule_groups = {}
    self.others_rule_group = Bali::RuleGroup.new(target_class, "__*__")
  end

  def add_rule_group(rule_group)
    target_user = rule_group.subtarget
    if target_user == "__*__" || target_user == :"__*__"
      self.others_rule_group = rule_group
    else
      self.rule_groups[rule_group.subtarget] = rule_group
    end
  end

  def rules_for(subtarget)
    return others_rule_group if subtarget == "__*__"
    subtarget = Bali::RuleGroup.canon_name(subtarget)
    self.rule_groups[subtarget]
  end

  # options can contains:
  #  :target_class => identifying the target class on which the clone will be applied
  def clone(options = {})
    target_class = options.fetch(:target_class)
    cloned_rc = Bali::RuleClass.new(target_class)

    rule_groups.each do |subtarget, rule_group|
      rule_group_clone = rule_group.clone
      rule_group_clone.target = target_class
      cloned_rc.add_rule_group(rule_group_clone)
    end

    others_rule_group_clone = others_rule_group.clone
    others_rule_group_clone.target = target_class
    cloned_rc.others_rule_group = others_rule_group_clone

    cloned_rc
  end
end
