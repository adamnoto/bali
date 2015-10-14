module Bali::Judger
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

  class Judge
    attr_accessor :original_subtarget
    attr_accessor :subtarget
    attr_accessor :auth_level
    attr_accessor :operation
    # record can be the class, or an instance of a class
    attr_accessor :record

    # determine if this judger should not call other judger
    attr_accessor :cross_checking

    # this class is abstract, shouldn't be initialized
    def initialize(deconstruct = true)
      if deconstruct
        raise Bali::Error, "Bali::Judge::Judger is abstract, construct by using build!"
      end
      self
    end 

    def self.build(auth_level, options = {})
      judge = nil
      if auth_level == :can
        judge = Bali::Judger::PositiveJudge.new
      elsif auth_level == :cannot
        judge = Bal::Judger::NegativeJudge.new
      else
        raise Bali::Error, "Unable to find judge for `#{auth_level}` case"
      end

      judge.original_subtarget = options.fetch(:original_subtarget)
      judge.subtarget = options.fetch(:subtarget)
      judge.operation = options.fetch(:operation)
      judge.record = options.fetch(:record)
      
      judge
    end

    def clone
      new_judge = Judge.new
      new_judge.subtarget = subtarget
      new_judge.auth_level = auth_level
      new_judge.operation = operation
      new_judge.record = record
      new_judge.cross_checking = cross_checking
      new_judge.original_subtarget = original_subtarget

      new_judge
    end

    def record_class
      record.is_a?(Class) ? record : record.class
    end

    def rule_group
      unless @rule_group_checked
        @rule_group = Bali::Integrators::Rule.rule_group_for(record_class, subtarget)
        @rule_group_checked = true
      end
      @rule_group
    end

    def other_rule_group
      unless @other_rule_group_checked
        @other_rule_group = Bali::Integrators::Rule.rule_group_for(record_class, "__*__")
        @other_rule_group_checked = true
      end
      @other_rule_group
    end

    def rule
      unless @rule_checked
        self.rule = rule_group.get_rule(auth_level, operation)
      end
      @rule
    end

    def rule=(the_rule)
      @rule = the_rule
      @rule_checked = true
      @rule
    end

    def otherly_rule
      unless @otherly_rule_checked
        # retrieve rule from others group
        @otherly_rule = other_rule_group.get_rule(auth_level, operation)
        @otherly_rule_checked = true
      end
      @otherly_rule
    end

    # return either true or false
    def judgement
      # default of can? is false whenever RuleClass for that class is undefined
      # or RuleGroup for that subtarget is not defined
      if rule_group.nil?
        if other_rule_group.nil?
          # no more chance for checking
          return natural_value 
        end
      end

      if need_to_check_for_intervention? 
        return check_intervention
      end

      if rule_group && rule_group.plant? &&
          rule.nil? && otherly_rule.nil?
        return natural_value
      end

      if rule.nil?
        cross_check_value = nil
        # default if can? for undefined rule is false, after related clause
        # cannot be found in cannot?
        unless cross_check
          self_clone = self.clone
          self_clone.cross_check = true
          self_clone.auth_level = reverse_auth_level 
          cross_check_value = self_clone.judge
        end 

        if can_use_otherly_rule?
          # give chance to check at others block
          rule = otherly_rule
        else
          cross_check_reverse_value
        end
      end

      if rule
        if rule.has_decider?
          return get_decider_result(rule, original_subtarget, record)
        else
          return default_positive_return_value
        end
      end

      # return fuzy if otherly rule defines contrary to this auth_level
      if other_rule_group.get_rule(reverse_auth_level, operation)
        return default_negative_fuzy_return_value
      end

      return natural_value
    end

    def need_to_check_for_intervention?
      raise "Abstract method called"
    end

    def check_intervention
      raise "Abstract method undefined"
    end

    def  default_return_value
      raise "Abstract method undefined"
    end

    def default_value_if_rule_class_undefined
      raise "Abstract method undefined"
    end

    private
      def should_reverse_judging?
        self.cross_checking == false
      end

    def bali_cannot?(subtarget, operation, record = self, options = {})
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
          return get_decider_result(rule, original_subtarget, record)
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

    # what is the result when decider is executed
    # rule: the rule object
    # original subtarget: raw, unprocessed arugment passed as subtarget
    def get_decider_result(rule, original_subtarget, record)
      # must test first
      decider = rule.decider
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
    end

  end
end
