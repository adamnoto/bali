# class that will be included in each instantiated target classes as defined
# in map_rules
module Bali::Objector
  def self.included(base)
    base.extend Bali::Objector::Statics
  end

  def can?(subtargets, operation) 
    self.class.can?(subtargets, operation, self)
  end

  def cant?(subtargets, operation)
    self.class.cant?(subtargets, operation, self)
  end
end

module Bali::Objector::Statics

  # will return array
  def __translate_subtarget_roles__(_subtarget_roles)
    if _subtarget_roles.is_a?(String) || _subtarget_roles.is_a?(Symbol) || _subtarget_roles.is_a?(NilClass)
      return [_subtarget_roles]
    elsif _subtarget_roles.is_a?(Array)
      return _subtarget_roles
    else
      # this case, _subtarget_roles is an object but not a symbol or a string
      # let's try to deduct subtarget's roles

      _subtarget = _subtarget_roles
      _subtarget_class = _subtarget.class.to_s
      
      # variable to hold deducted role of the passed object
      deducted_roles = nil

      Bali::TRANSLATED_SUBTARGET_ROLES.each do |subtarget_class, roles_field_name|
        if _subtarget_class == subtarget_class
          deducted_roles = _subtarget.send(roles_field_name)
          if deducted_roles.is_a?(String) || deducted_roles.is_a?(Symbol)
            deducted_roles = [deducted_roles]
            break
          elsif deducted_roles.is_a?(Array)
            break
          else
            # keep it nil if _subtarget_roles is not either String, Symbol or Array
            deducted_roles = nil
          end
        end # if matching class
      end # each TRANSLATED_SUBTARGET_ROLES

      return deducted_roles
    end # if
  end

  ### options passable to __can__? and __cant__? are:
  ### cross_action: if set to true wouldn't call its counterpart so as to prevent
  ###   overflowing stack
  ### original_subtarget: the original passed to can? and cant? before 
  ###   processed by  __translate_subtarget_roles__

  def __can__?(subtarget, operation, record = self, options = {})
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
      options[:cross_check] = true
      return !self.cant?(subtarget, operation, record, options)
    else
      if rule.has_decider?
        # must test first
        decider = rule.decider
        original_subtarget = options.fetch(:original_subtarget)
        case decider.arity
        when 0
          if rule.decider_type == :if
            if decider.()
              return true 
            else 
              return false
            end
          elsif rule.decider_type == :unless
            unless decider.()
              return true 
            else 
              return false 
            end
          end
        when 1
          if rule.decider_type == :if
            if decider.(record)
              return true 
            else 
              return false
            end
          elsif rule.decider_type == :unless
            unless decider.(record)
              return true 
            else 
              return false 
            end
          end
        when 2
          if rule.decider_type == :if
            if decider.(record, original_subtarget)
              return true 
            else 
              return false
            end
          elsif rule.decider_type == :unless
            unless decider.(record, original_subtarget)
              return true 
            else 
              return false 
            end
          end
        end
      else
        # rule is properly defined
        return true
      end
    end
  end

  def __cant__?(subtarget, operation, record = self, options = {})
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
      options[:cross_check] = true
      return !self.can?(subtarget, operation, record, options)
    else
      if rule.has_decider?
        decider = rule.decider
        original_subtarget = options.fetch(:original_subtarget)
        case decider.arity
        when 0
          if rule.decider_type == :if
            if decider.()
              return true 
            else 
              return false
            end
          elsif rule.decider_type == :unless
            unless decider.()
              return true 
            else 
              return false 
            end
          end
        when 1
          if rule.decider_type == :if
            if decider.(record)
              return true 
            else 
              return false
            end
          elsif rule.decider_type == :unless
            unless decider.(record)
              return true 
            else 
              return false 
            end
          end
        when 2
          if rule.decider_type == :if
            if decider.(record, original_subtarget)
              return true 
            else 
              return false
            end
          elsif rule.decider_type == :unless
            unless decider.(record, original_subtarget)
              return true 
            else 
              return false 
            end
          end
        end
      else
        return true # rule is properly defined
      end # if rule has decider
    end # if rule is nil
  end

  def can?(subtarget_roles, operation, record = self, options = {})
    subs = __translate_subtarget_roles__(subtarget_roles)
    # well, it is largely not used unless decider's is 2 arity
    options[:original_subtarget] = options[:original_subtarget].nil? ? subtarget_roles : options[:original_subtarget]

    subs.each do |subtarget|
      can_value = __can__?(subtarget, operation, record, options)
      return true if can_value == true
    end
    false
  rescue => e
    raise Bali::ObjectionError, e.message
  end

  def cant?(subtarget_roles, operation, record = self, options = {})
    subs = __translate_subtarget_roles__ subtarget_roles
    options[:original_subtarget] = options[:original_subtarget].nil? ? subtarget_roles : options[:original_subtarget]

    subs.each do |subtarget|
      cant_value = __cant__?(subtarget, operation, record, options)
      return false if cant_value == false
    end
    true
  rescue => e 
    raise Bali::ObjectionError, e.message
  end
end
