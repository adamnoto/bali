module Bali::Judger
  class NegativeJudge < Judge
    def initialize
      super(false)
    end

    def auth_level
      :cant
    end

    def reverse_auth_level
      :can
    end

    def zeus_return_value
      BALI_FALSE
    end

    def plant_return_value
      BALI_TRUE
    end

    def default_positive_return_value
      BALI_TRUE
    end

    def default_negative_fuzy_return_value
      BALI_FUZY_TRUE
    end

    # cant? by default return true when
    def natural_value
      BALI_TRUE
    end

    def need_to_check_for_intervention?
      rule_group && rule_group.plant?
    end
  end
end
