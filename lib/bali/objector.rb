# module that will be included in each instantiated target classes as defined
# in map_rules
module Bali::Objector
  def self.included(base)
    base.extend Bali::Objector::Statics
  end

  # check whether user can/cant perform an operation, return true when positive
  # or false otherwise
  def can?(subtargets, operation)
    self.class.can?(subtargets, operation, self)
  end

  # check whether user can/cant perform an operation, raise an error when access
  # is denied
  def can!(subtargets, operation)
    self.class.can!(subtargets, operation, self)
  end

  # check whether user can/cant perform an operation, return true when negative
  # or false otherwise
  def cannot?(subtargets, operation)
    self.class.cannot?(subtargets, operation, self)
  end

  # check whether user can/cant perform an operation, raise an error when access
  # is given
  def cannot!(subtargets, operation)
    self.class.cannot!(subtargets, operation, self)
  end

  def cant?(subtargets, operation)
    puts "Deprecation Warning: please use cannot? instead, cant? will be deprecated on major release 3.0"
    cannot?(subtargets, operation)
  end

  def cant!(subtargets, operation)
    puts "Deprecation Warning: please use cannot! instead, cant! will be deprecated on major release 3.0"
    cannot!(subtargets, operation)
  end
end

module Bali::Objector::Statics
  # FUZY-ed value is happen when it is not really clear, need further cross checking,
  # whether it is really allowed or not. It happens for example in block with others, such as this:
  #
  # role :finance do
  #   cannot :view
  # end
  # others do
  #   can :view
  #   can :index
  # end
  #
  # In the example above, objecting cannot view on finance will result in STRONG_FALSE, but
  # objecting can index on finance will result in FUZY_TRUE.
  #
  # Eventually, all FUZY value will be normal TRUE or FALSE if no definite counterpart
  # is found/defined
  BALI_FUZY_FALSE = -2
  BALI_FUZY_TRUE = 2
  BALI_FALSE = -1
  BALI_TRUE = 1

  # translate response for value above to traditional true/false
  def bali_translate_response(bali_bool_value)
    raise Bali::Error, "Expect bali value to be an integer" unless bali_bool_value.is_a?(Integer)
    if bali_bool_value < 0
      return false
    elsif bali_bool_value > 0
      return true
    else
      raise Bali::Error, "Bali bool value can either be negative or positive integer"
    end
  end

  # will return array
  def bali_translate_subtarget_roles(_subtarget_roles)
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
          if deducted_roles.is_a?(String) || deducted_roles.is_a?(Symbol) || deducted_roles.is_a?(NilClass)
            deducted_roles = [deducted_roles]
            break
          elsif deducted_roles.is_a?(Array)
            break
          end
        end # if matching class
      end # each TRANSLATED_SUBTARGET_ROLES

      if deducted_roles.nil?
        raise Bali::AuthorizationError, "Bali does not know how to process roles: #{_subtarget_roles}"
      end

      return deducted_roles
    end # if
  end

  ### options passable to bali_can? and bali_cannot? are:
  ### cross_action: if set to true wouldn't call its counterpart so as to prevent
  ###   overflowing stack
  ### original_subtarget: the original passed to can? and cannot? before
  ###   processed by bali_translate_subtarget_roles

  def bali_can?(subtarget, operation, record = self, options = {})
    # if performed on a class-level, don't call its class or it will return
    # Class. That's not what is expected.
    if self.is_a?(Class)
      klass = self
    else
      klass = self.class
    end

    rule_group = Bali::Integrators::Rule.rule_group_for(klass, subtarget)
    other_rule_group = Bali::Integrators::Rule.rule_group_for(klass, "__*__")

    rule = nil

    # default of can? is false whenever RuleClass for that class is undefined
    # or RuleGroup for that subtarget is not defined
    if rule_group.nil?
      # no more chance for checking
      return BALI_FALSE if other_rule_group.nil?
    else
      # get the specific rule from its own role block
      rule = rule_group.get_rule(:can, operation)
    end

    # retrieve rule from others group
    otherly_rule = other_rule_group.get_rule(:can, operation)

    # godly subtarget is allowed to do as he wishes
    # so long that the rule is not specificly defined
    # or overwritten by subsequent rule
    if rule_group && rule_group.zeus?
      if rule.nil?
        _options = options.dup
        _options[:cross_check] = true
        _options[:original_subtarget] = original_subtarget if _options[:original_subtarget].nil?

        check_val = self.bali_cannot?(subtarget, operation, record, _options)

        # check further whether cant is defined to overwrite this can_all
        if check_val == BALI_TRUE
          return BALI_FALSE
        else
          return BALI_TRUE
        end
      end
    end

    # do after crosscheck
    # plan subtarget is not allowed unless spesificly defined
    return BALI_FALSE if rule_group && rule_group.plant? && rule.nil? && otherly_rule.nil?

    if rule.nil?
      # default if can? for undefined rule is false, after related clause
      # cannot be found in cannot?

      unless options[:cross_check]
        options[:cross_check] = true
        cross_check_value = self.bali_cannot?(subtarget, operation, record, options)
      end

      # either if rule from others block is defined, and the result so far is fuzy
      # or, otherly rule is defined, and it is still a cross check
      # plus, the result is not a definite BALI_TRUE/BALI_FALSE
      #
      # rationalisation:
      # 1. Definite answer such as BALI_TRUE and BALI_FALSE is to be prioritised over
      #    FUZY answer, because definite answer is not gathered from others block where
      #    FUZY answer is. Therefore, it is an intended result
      # 2. If the answer is FUZY, otherly_rule only be considered if the result
      #    is either FUZY TRUE or FUZY FALSE, or
      # 3. Or, when already in cross check mode, we cannot retrieve cross_check_value
      #    what we can is instead, if otherly rule is available, just to try the odd
      if (otherly_rule && cross_check_value && !(cross_check_value == BALI_TRUE || cross_check_value == BALI_FALSE)) ||
          (otherly_rule && (cross_check_value == BALI_FUZY_FALSE || cross_check_value == BALI_FUZY_TRUE)) ||
          (otherly_rule && options[:cross_check] && cross_check_value.nil?)
        # give chance to check at the others block
        rule = otherly_rule
      else
        # either the return is not fuzy, or otherly rule is undefined
        if cross_check_value == BALI_TRUE
          return BALI_FALSE
        elsif cross_check_value == BALI_FALSE
          return BALI_TRUE
        end
      end
    end

    if rule
      if rule.has_decider?
        # must test first
        decider = rule.decider
        original_subtarget = options.fetch(:original_subtarget)
        case decider.arity
        when 0
          if rule.decider_type == :if
            return decider.() ? BALI_TRUE : BALI_FALSE
          elsif rule.decider_type == :unless
            unless decider.()
              return BALI_TRUE
            else
              return BALI_FALSE
            end
          end
        when 1
          if rule.decider_type == :if
            return decider.(record) ? BALI_TRUE : BALI_FALSE
          elsif rule.decider_type == :unless
            unless decider.(record)
              return BALI_TRUE
            else
              return BALI_FALSE
            end
          end
        when 2
          if rule.decider_type == :if
            return decider.(record, original_subtarget) ? BALI_TRUE : BALI_FALSE
          elsif rule.decider_type == :unless
            unless decider.(record, original_subtarget)
              return BALI_TRUE
            else
              return BALI_FALSE
            end
          end
        end
      else
        # rule is properly defined
        return BALI_TRUE
      end
    end

    # return fuzy if otherly rule defines contrary to this (can)
    if other_rule_group.get_rule(:cannot, operation)
      return BALI_FUZY_FALSE
    else
      return BALI_FALSE
    end
  end

  def bali_cannot?(subtarget, operation, record = self, options = {})
    if self.is_a?(Class)
      klass = self
    else
      klass = self.class
    end

    rule_group = Bali::Integrators::Rule.rule_group_for(klass, subtarget)
    other_rule_group = Bali::Integrators::Rule.rule_group_for(klass, "__*__")

    rule = nil

    # default of cannot? is true whenever RuleClass for that class is undefined
    # or RuleGroup for that subtarget is not defined
    if rule_group.nil?
      return BALI_TRUE if other_rule_group.nil?
    else
      # get the specific rule from its own role block
      rule = rule_group.get_rule(:cannot, operation)
    end

    otherly_rule = other_rule_group.get_rule(:cannot, operation)
    # plant subtarget is not allowed to do things unless specificly defined
    if rule_group && rule_group.plant?
      if rule.nil?
        _options = options.dup
        _options[:cross_check] = true
        _options[:original_subtarget] = original_subtarget if _options[:original_subtarget].nil?

        # check further whether defined in can?
        check_val = self.bali_can?(subtarget, operation, record, _options)

        if check_val == BALI_TRUE
          return BALI_FALSE # well, it is defined in can, so it must overwrite this cant_all rule
        else
          # plant, and then rule is not defined for further inspection. stright
          # is not allowed to do this thing
          return BALI_TRUE
        end
      end
    end

    if rule.nil?
      unless options[:cross_check]
        options[:cross_check] = true
        cross_check_value = self.bali_can?(subtarget, operation, record, options)
      end

      if (otherly_rule && cross_check_value && !(cross_check_value == BALI_TRUE || cross_check_value == BALI_FALSE)) ||
          (otherly_rule && (cross_check_value == BALI_FUZY_FALSE || cross_check_value == BALI_FUZY_TRUE)) ||
          (otherly_rule && options[:cross_check] && cross_check_value.nil?)
        rule = otherly_rule
      else
        if cross_check_value == BALI_TRUE
          # from can? because of cross check, then it should be false
          return BALI_FALSE
        elsif cross_check_value == BALI_FALSE
          # from can? because of cross check returning false
          # then it should be true, that is, cannot
          return BALI_TRUE
        end
      end
    end

    # do after cross check
    # godly subtarget is not to be prohibited in his endeavours
    # so long that no specific rule about this operation is defined
    return BALI_FALSE if rule_group && rule_group.zeus? && rule.nil? && otherly_rule.nil?

    if rule
      if rule.has_decider?
        decider = rule.decider
        original_subtarget = options.fetch(:original_subtarget)
        case decider.arity
        when 0
          if rule.decider_type == :if
            return decider.() ? BALI_TRUE : BALI_FALSE
          elsif rule.decider_type == :unless
            unless decider.()
              return BALI_TRUE
            else
              return BALI_FALSE
            end
          end
        when 1
          if rule.decider_type == :if
            return decider.(record) ? BALI_TRUE : BALI_FALSE
          elsif rule.decider_type == :unless
            unless decider.(record)
              return BALI_TRUE
            else
              return BALI_FALSE
            end
          end
        when 2
          if rule.decider_type == :if
            return decider.(record, original_subtarget) ? BALI_TRUE : BALI_FALSE
          elsif rule.decider_type == :unless
            unless decider.(record, original_subtarget)
              return BALI_TRUE
            else
              return BALI_FALSE
            end
          end
        end
      else
        return BALI_TRUE # rule is properly defined
      end # if rule has decider
    end # if rule is nil

    # return fuzy if otherly rule defines contrary to this cannot rule
    if other_rule_group.get_rule(:can, operation)
      return BALI_FUZY_TRUE
    else
      BALI_TRUE
    end
  end # bali cannot

  def can?(subtarget_roles, operation, record = self, options = {})
    subs = bali_translate_subtarget_roles(subtarget_roles)
    # well, it is largely not used unless decider's is 2 arity
    options[:original_subtarget] = options[:original_subtarget].nil? ? subtarget_roles : options[:original_subtarget]

    can_value = BALI_FALSE
    role = nil

    subs.each do |subtarget|
      next if can_value == BALI_TRUE
      role = subtarget
      can_value = bali_can?(role, operation, record, options)
    end

    if can_value == BALI_FALSE && block_given?
      yield options[:original_subtarget], role, bali_translate_response(can_value)
    end
    bali_translate_response can_value
  rescue => e
    if e.is_a?(Bali::AuthorizationError)
      raise e
    else
      raise Bali::ObjectionError, e.message
    end
  end

  def cant?(subtarget_roles, operation, record = self, options = {})
    puts "Deprecation Warning: please use cannot? instead, cant? will be deprecated on major release 3.0"
    cannot?(subtarget_roles, operation, record, options)
  end

  def cannot?(subtarget_roles, operation, record = self, options = {})
    subs = bali_translate_subtarget_roles subtarget_roles
    options[:original_subtarget] = options[:original_subtarget].nil? ? subtarget_roles : options[:original_subtarget]

    cant_value = BALI_TRUE

    subs.each do |subtarget|
      next if cant_value == BALI_FALSE
      cant_value = bali_cannot?(subtarget, operation, record, options)
      if cant_value == BALI_FALSE
        role = subtarget
        if block_given?
          yield options[:original_subtarget], role, bali_translate_response(cant_value)
        end
      end
    end

    bali_translate_response cant_value
  rescue => e
    if e.is_a?(Bali::AuthorizationError)
      raise e
    else
      raise Bali::ObjectionError, e.message
    end
  end

  def can!(subtarget_roles, operation, record = self, options = {})
    can?(subtarget_roles, operation, record, options) do |original_subtarget, role, can_value|
      if !can_value
        auth_error = Bali::AuthorizationError.new
        auth_error.auth_level = :can
        auth_error.operation = operation
        auth_error.role = role
        auth_error.target = record
        auth_error.subtarget = original_subtarget

        if role
          auth_error.subtarget = original_subtarget if !(original_subtarget.is_a?(Symbol) || original_subtarget.is_a?(String) || original_subtarget.is_a?(Array))
        end

        raise auth_error
      end
    end
  end

  def cant!(subtarget_roles, operation, record = self, options = {})
    puts "Deprecation Warning: please use cannot! instead, cant! will be deprecated on major release 3.0"
    cannot!(subtarget_roles, operation, record, options)
  end

  def cannot!(subtarget_roles, operation, record = self, options = {})
    cannot?(subtarget_roles, operation, record, options) do |original_subtarget, role, cant_value|
      if cant_value == false
        auth_error = Bali::AuthorizationError.new
        auth_error.auth_level = :cannot
        auth_error.operation = operation
        auth_error.role = role
        auth_error.target = record
        auth_error.subtarget = original_subtarget

        if role
          auth_error.subtarget = original_subtarget if !(original_subtarget.is_a?(Symbol) || original_subtarget.is_a?(String) || original_subtarget.is_a?(Array))
        end

        raise auth_error
      end
    end
  end
end
