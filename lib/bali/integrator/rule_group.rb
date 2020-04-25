module Bali
  module Integrator
    module RuleGroup

      module_function

      # attempt to search the rule group,
      # but if not exist, will return nil
      def for(target_class, subtarget)
        rule_class = Bali::Integrator::RuleClass.for(target_class)
        rule_class.nil? ? nil : rule_class.rules_for(subtarget)
      end

      # make a rule group a zeus, that is, he can do everything, unless
      # specified more specifically otherwise by a definite rule
      def make_zeus(rule_group)
        rule_group.zeus = true
        rule_group.plant = false
      end

      # make a rule group a plant, that is, he cant do everything, unless
      # specified more specifically otherwise by a definite rule
      def make_plant(rule_group)
        rule_group.plant = true
        rule_group.zeus = false
      end
    end
  end
end
