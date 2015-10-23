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
    attr_accessor :operation
    # record can be the class, or an instance of a class
    attr_accessor :record

    # determine if this judger should not call other judger
    attr_accessor :cross_checking

    # this class is abstract, shouldn't be initialized
    def initialize(unconstructable = true)
      if unconstructable
        raise Bali::Error, "Bali::Judge::Judger is unconstructable, properly construct by using build to get a concrete class!"
      end
      self
    end 

    def self.build(auth_level, options = {})
      judge = nil
      if auth_level == :can
        judge = Bali::Judger::PositiveJudge.new
      elsif auth_level == :cannot
        judge = Bali::Judger::NegativeJudge.new
      else
        raise Bali::Error, "Unable to find judge for `#{auth_level}` case"
      end

      judge.original_subtarget = options[:original_subtarget]
      judge.subtarget = options[:subtarget]
      judge.operation = options[:operation]
      judge.record = options[:record]
      judge.cross_checking = false

      judge
    end

    def clone(options = {})
      if options[:reverse]
        new_judge = Bali::Judger::Judge.build(self.reverse_auth_level)
      else
        new_judge = Bali::Judger::Judge.build(self.auth_level)
      end

      new_judge.subtarget = subtarget
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
        # rule group may be nil, for when user checking for undefined rule group
        if rule_group
          @rule = rule_group.get_rule(auth_level, operation)
        else
          self.rule = nil
        end
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
        if other_rule_group
          # retrieve rule from others group
          @otherly_rule = other_rule_group.get_rule(auth_level, operation)
          @otherly_rule_checked = true
        end
      end
      @otherly_rule
    end

    # return either true or false
    # options can specify if returning raw, by specifying holy: true
    def judgement(options = {})
      # the divine judgement will come to thee, O Thou 
      # the doer of truth. return raw, untranslated to true/false.
      our_holy_judgement = nil

      # default of can? is false whenever RuleClass for that class is undefined
      # or RuleGroup for that subtarget is not defined
      if rule_group.nil?
        if other_rule_group.nil?
          # no more chance for checking
          our_holy_judgement = natural_value 
        end
      end

      if our_holy_judgement.nil? && need_to_check_for_intervention? 
        our_holy_judgement = check_intervention
      end

      if our_holy_judgement.nil? && 
          rule_group && rule_group.plant? &&
          rule.nil? && otherly_rule.nil?
        our_holy_judgement = natural_value
      end

      if our_holy_judgement.nil? && rule.nil?
        cross_check_value = nil
        # default if can? for undefined rule is false, after related clause
        # cannot be found in cannot?
        unless cross_checking
          reversed_self = self.clone reverse: true
          reversed_self.cross_checking = true
          cross_check_value = reversed_self.judgement holy: true
        end 

        # if cross check value nil, then the reverse rule is not defined,
        # let's determine whether he is zeus or plant
        if cross_check_value.nil?
          # rule_group can be nil for when user checking under undefined rule-group
          if rule_group
            if rule_group.plant?
              our_holy_judgement = plant_return_value
            end

            if rule_group.zeus?
              our_holy_judgement = zeus_return_value
            end 
          end # if rule_group exist
        else
          # process value from cross checking
          
          if can_use_otherly_rule?(cross_check_value, cross_checking)
            # give chance to check at others block
            self.rule = otherly_rule
          else
            our_holy_judgement = cross_check_reverse_value(cross_check_value)
          end
        end
      end # if our judgement nil and rule is nil

      # if our holy judgement is still nil, but rule is defined
      if our_holy_judgement.nil? && rule
        if rule.has_decider?
          our_holy_judgement = get_decider_result(rule, original_subtarget, record)
        else
          our_holy_judgement = default_positive_return_value
        end
      end

      # return fuzy if otherly rule defines contrary to this auth_level
      if our_holy_judgement.nil? && rule.nil? && (other_rule_group && other_rule_group.get_rule(reverse_auth_level, operation))
        if rule_group && (rule_group.zeus? || rule_group.plant?)
          # don't overwrite our holy judgement with fuzy value if rule group
          # zeus/plant, because zeus/plant is more definite than any fuzy values
          # eventhough the rule is abstractly defined
        else
          our_holy_judgement = default_negative_fuzy_return_value
        end
      end

      # if at this point still nil, well, 
      # return the natural value for this judge
      if our_holy_judgement.nil?
        if otherly_rule
          our_holy_judgement = BALI_FUZY_TRUE
        else
          our_holy_judgement = natural_value
        end
      end

      holy = !!options[:holy]
      return holy ? our_holy_judgement : translate_holy_judgement(our_holy_judgement)
    end

    private
      # translate response for value above to traditional true/false
      # holy judgement refer to non-standard true/false being used inside Bali
      # which need to be translated from other beings to know
      def translate_holy_judgement(bali_bool_value)
        unless bali_bool_value.is_a?(Integer)
          raise Bali::Error, "Expect bali value to be an Integer, got: `#{bali_bool_value}`" 
        end
        if bali_bool_value < 0
          return false
        elsif bali_bool_value > 0
          return true
        end
      end

      def can_use_otherly_rule?(cross_check_value, is_cross_checking)
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
        (!otherly_rule.nil? && cross_check_value && !(cross_check_value == BALI_TRUE || cross_check_value == BALI_FALSE)) ||
          (!otherly_rule.nil? && (cross_check_value == BALI_FUZY_FALSE || cross_check_value == BALI_FUZY_TRUE)) ||
          (!otherly_rule.nil? && is_cross_checking && cross_check_value.nil?)
      end

      # if after cross check (checking for cannot) the return is false,
      # meaning for us, (checking for can), the return have to be true
      def cross_check_reverse_value(cross_check_value)
        # either the return is not fuzy, or otherly rule is undefined
        if cross_check_value == BALI_TRUE
          return BALI_FALSE
        elsif cross_check_value == BALI_FALSE
          return BALI_TRUE
        elsif cross_check_value == BALI_FUZY_FALSE 
          return BALI_FUZY_TRUE
        elsif cross_check_value == BALI_FUZY_TRUE
          return BALI_FUZY_FALSE
        else
          raise Bali::Error, "Unknown how to process cross check value: `#{cross_check_value}`"
        end
      end # cross_check_reverse_value

      def check_intervention
        if rule.nil?
          self_clone = self.clone reverse: true
          self_clone.cross_checking = true

          check_val = self_clone.judgement holy: true

          # check further whether contradicting rule is defined to overwrite this
          # super-power either can_all or cannot_all rule
          if check_val == BALI_TRUE
            # it is defined, must overwrite
            return BALI_FALSE
          else
            # futher inspection said no such overwriting value is exist
            return BALI_TRUE
          end # check_val
        end # if rule nil
      end # check intervention

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
  end # class
end # module
