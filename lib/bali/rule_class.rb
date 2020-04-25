# the parent of all Bali::RuleGroup.
class Bali::RuleClass
  attr_reader :model_class
  attr_accessor :rule_groups
  attr_accessor :others_rule_group

  def self.for(target)
    rule_class = Bali::RULE_CLASS_MAP[target.to_s]

    if rule_class.nil?
      rule_class_maker_str = target.to_s + Bali.config.suffix
      rule_class_maker = rule_class_maker_str.safe_constantize

      if rule_class_maker && rule_class_maker.ancestors.include?(Bali::Rules)
        rule_class = rule_class_maker.current_rule_class
        Bali::RULE_CLASS_MAP[target.to_s] = rule_class
      end
    end

    rule_class
  end

  def initialize(model_class)
    @model_class = model_class
    @rule_groups = {}
    @others_rule_group = Bali::RuleGroup.new(model_class, "__*__")
  end

  def add_rule_group(rule_group)
    target_user = rule_group.subtarget
    if target_user == "__*__" || target_user == :"__*__"
      @others_rule_group = rule_group
    else
      @rule_groups[rule_group.subtarget] = rule_group
    end
  end

  def rules_for(subtarget)
    return others_rule_group if subtarget == "__*__"
    subtarget = Bali::RuleGroup.canon_name(subtarget)
    @rule_groups[subtarget]
  end
end
