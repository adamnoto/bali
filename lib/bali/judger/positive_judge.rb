module Bali::Judger
  class PositiveJudge < Judge
    def initialize
      super(false)
    end

    def auth_level
      :can
    end

    def reverse_auth_level
      :cant
    end

    def zeus_return_value
      BALI_TRUE
    end

    def plant_return_value
      BALI_FALSE
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
  end # positive judger
end # module judger
