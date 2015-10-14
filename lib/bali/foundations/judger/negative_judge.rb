module Bali::Judger
  class NegativeJudge < Judge
    def initialize
      super(false)
      self.auth_level = false
    end

    def reverse_auth_level
      :can
    end

    def default_positive_return_value

    end

    def default_negative_fuzy_return_value

    end

    # cannot? by default return true when
    def natural_value
      BALI_TRUE
    end
    
    def need_to_check_for_intervention?
      rule_group && rule_group.plant?
    end

    def check_intervention_for_zeus

    end

    def can_use_otherly_rule?

    end

    def cross_check_reverse_value

    end
  end
end
