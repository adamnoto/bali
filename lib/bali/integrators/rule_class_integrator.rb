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
        raise Bali::DslError, "Target must be a class" unless target.is_a?(Class)
        Bali::RULE_CLASS_MAP[target.to_s]
      end

      # add a new rule class
      def add(rule_class)
        if rule_class.is_a?(Bali::RuleClass)
          target = rule_class.target_class

          raise Bali::DslError, "Target must be a class" unless target.is_a?(Class)

          Bali::RULE_CLASS_MAP[target.to_s] = rule_class
          rule_class
        else
          raise Bali::DslError, "Only allow instance of Bali::RuleClass"
        end
      end # add_rule_class

    end
  end
end
