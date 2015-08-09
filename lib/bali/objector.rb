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
    rule_group = Bali.rule_group_for(subtarget, operation)
    rule = rule_group.get_rule(:can, operation)

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

  def cant?(subtarget, operation)
    rule_group = Bali.rule_group_for(subtarget, operation)
    rule = rule_group.get_rule(:cant, operation)

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
