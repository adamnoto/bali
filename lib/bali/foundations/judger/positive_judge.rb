module Bali::Judger
  class PositiveJudge < Judge
    def initialize
      super(false)
      self.auth_level = true
    end

    def reverse_auth_level
      :cannot
    end

    def default_positive_return_value
      BALI_TRUE
    end

    def default_negative_fuzy_return_value
      BALI_FUZY_FALSE
    end

    # value that is natural to be returned by the jury
    # can? by default return false
    def natural_value
      BALI_FALSE
    end

    def need_to_check_for_intervention?
      rule_group && rule_group.zeus?
    end

    def check_intervention
      if rule.nil?
        self_clone = self.clone
        self_clone.auth_level = reverse_auth_level
        self_clone.cross_check = true

        check_val = self_clone.judge 

        # check further whether cant is defined to overwrite this can_all
        if check_val == BALI_TRUE
          return BALI_FALSE
        else
          return BALI_TRUE
        end # check_val
      end # if rule nil
    end # check intervention

    def can_use_otherly_rule?
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
      return (otherly_rule && cross_check_value && !(cross_check_value == BALI_TRUE || cross_check_value == BALI_FALSE)) ||
            (otherly_rule && (cross_check_value == BALI_FUZY_FALSE || cross_check_value == BALI_FUZY_TRUE)) ||
            (otherly_rule && options[:cross_check] && cross_check_value.nil?)

    end

    # if after cross check (checking for cannot) the return is false,
    # meaning we (checking for can) the return have to be true
    def cross_check_reverse_value
      # either the return is not fuzy, or otherly rule is undefined
      if cross_check_value == BALI_TRUE
        return BALI_FALSE
      elsif cross_check_value == BALI_FALSE
        return BALI_TRUE
      end
    end # cross_check_reverse_value

  end # positive judger
end # module judger
