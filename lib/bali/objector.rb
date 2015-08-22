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
    self.class.cant?(subtarget, operation, self)
  end
end

module Bali::Objector::Statics
  def can?(subtarget, operation, record = self, options = {})
    # if performed on a class-level, don't call its class or it will return
    # Class. That's not what is expected.
    if self.is_a?(Class)
      rule_group = Bali.rule_group_for(self, subtarget)
    else
      rule_group = Bali.rule_group_for(self.class, subtarget)
    end

    # default of can? is false whenever RuleClass for that class is undefined
    # or RuleGroup for that subtarget is not defined
    return false if rule_group.nil?

    # get the specific rule
    rule = rule_group.get_rule(:can, operation)

    # plan subtarget is not allowed unless spesificly defined
    return false if rule_group.plant? && rule.nil?

    # godly subtarget is allowed to do as he wishes
    # so long that the rule is not specificly defined
    # or overwritten by subsequent rule
    if rule_group.zeus?
      if rule.nil?
        # check further whether cant is defined to overwrite this can_all
        if self.cant?(subtarget, operation, record, cross_check: true)
          return false
        else
          return true
        end
      end
    end
    
    if rule.nil?
      # default if can? for undefined rule is false, after related clause
      # cannot be found in cant?
      return false if options[:cross_check]
      return !self.cant?(subtarget, operation, record, cross_check: true)
    else
      if rule.has_decider?
        # must test first
        decider = rule.decider
        if decider.arity == 0
          return (rule.decider_type == :if) ? decider.() == true : decider.() == false
        else
          return (rule.decider_type == :if) ? decider.(record) == true : decider.(record) == false
        end
      else
        # rule is properly defined
        return true
      end
    end

  end

  def cant?(subtarget, operation, record = self, options = {})
    if self.is_a?(Class)
      rule_group = Bali.rule_group_for(self, subtarget)
    else
      rule_group = Bali.rule_group_for(self.class, subtarget)
    end

    # default of cant? is true whenever RuleClass for that class is undefined
    # or RuleGroup for that subtarget is not defined
    return true if rule_group.nil?

    rule = rule_group.get_rule(:cant, operation)

    # godly subtarget is not to be prohibited in his endeavours
    # so long that no specific rule about this operation is defined
    return false if rule_group.zeus? && rule.nil?

    # plant subtarget is not allowed to do things unless specificly defined
    if rule_group.plant?
      if rule.nil?
        # check further whether defined in can?
        if self.can?(subtarget, operation, record, cross_check: true)
          return false # well, it is defined in can, so it must overwrite this cant_all rule
        else
          # plant, and then rule is not defined for further inspection. stright
          # is not allowed to do this thing
          return true
        end
      end
    end

    # if rule cannot be found, then true is returned for cant? unless 
    # can? is defined exactly for the same target, and subtarget, and record (if given)
    if rule.nil?
      return true if options[:cross_check]
      return !self.can?(subtarget, operation, record, cross_check: true)
    else
      if rule.has_decider?
        decider = rule.decider
        if decider.arity == 0
          return (rule.decider_type == :if) ? decider.() == true : decider.() == false
        else
          return (rule.decider_type == :if) ? decider.(record) == true : decider.(record) == false
        end
      else
        return true # rule is properly defined
      end # if rule has decider
    end # if rule is nil
  end
end
