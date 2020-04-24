module Bali
  module Integrator
    # high-level functions to access and manage RuleClass classes
    module RuleClass
      
      module_function

      # return all rule classes
      def all
        Bali::RULE_CLASS_MAP
      end

      # return all rule class of a target
      def for(target)
        Bali::RULE_CLASS_MAP[target.to_s]
      end

      # add a new rule class
      def add(rule_class)
        target = rule_class.target_class

        Bali::RULE_CLASS_MAP[target.to_s] = rule_class
        rule_class
      end # add_rule_class
    end
  end
end
