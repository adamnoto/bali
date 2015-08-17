# class that will be included in each instantiated target classes as defined
# in map_rules
module Bali::Objector
  def self.included(base)
    base.extend Bali::Objector::Statics
  end

  def can?(subtarget, operation) 
    self.class.can?(subtarget, operation, self)
  end

  def cant?(subtarget, operation)
    self.class.can?(subtarget, operation, self)
  end
end

module Bali::Objector::Statics
  def can?(subtarget, operation, record = self)
    # if performed on a class-level, don't call its class or it will return
    # Class. That's not what is expected.
    if self.is_a?(Class)
      rule_group = Bali.rule_group_for(self, subtarget)
    else
      rule_group = Bali.rule_group_for(self.class, subtarget)
    end

    rule = rule_group.get_rule(:can, operation)

    # godly subtarget is allowed to do as he wishes
    # so long that the rule is not specificly defined
    return true if rule_group.zeus? && rule.nil?
    
    # plan subtarget is not allowed unless spesificly defined
    return false if rule_group.plant? && rule.nil?

    # default to false when asked about can? but no rule to be found
    return false if rule.nil?

    if rule.has_decider?
      # must test first
      decider = rule.decider
      if decider.arity == 0
        decider.() == true
      else
        decider.(record) == true
      end
    else
      # rule is properly defined
      return true
    end
  end

  def cant?(subtarget, operation, record = self)
    if self.is_a?(Class)
      rule_group = Bali.rule_group_for(self, subtarget)
    else
      rule_group = Bali.rule_group_for(self.class, subtarget)
    end

    rule = rule_group.get_rule(:cant, operation)

    # godly subtarget is not to be prohibited in his endeavours
    # so long that no specific rule about this operation is defined
    return false if rule_group.zeus? && rule.nil?

    # plant subtarget is not allowed to do things unless specificly defined
    return true if rule_group.plant? && rule.nil?

    # default to true when asked about cant? but no rule to be found
    return true if rule.nil?

    if rule.has_decider?
      decider = rule.decider
      if decider.arity == 0
        decider.() == true
      else
        decider.(record) == true
      end
    end
  end
end
