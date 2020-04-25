module Bali
  module Integrator
    module Rule

      module_function

      # process conditional statement in rule definition
      # conditional hash: {if: proc} or {unless: proc}
      def embed_condition(rule, conditional_hash = nil)
        return if conditional_hash.nil?

        condition_type = conditional_hash.keys[0].to_s.downcase
        condition_type_symb = condition_type.to_sym

        if condition_type_symb == :if || condition_type_symb == :unless
          rule.decider = conditional_hash.values[0]
          rule.decider_type = condition_type_symb
        end
        nil
      end

      # to define can and cant is basically using this method
      # args can comprises of symbols, and hash (for condition)
      def add(auth_val, rule_group, *args)
        conditional_hash = nil
        operations = []

        # scan args for options
        args.each do |elm|
          if elm.is_a?(Hash)
            conditional_hash = elm
          else
            operations << elm
          end
        end

        # add operation one by one
        operations.each do |op|
          rule = Bali::Rule.new(auth_val, op)
          Bali::Integrator::Rule.embed_condition(rule, conditional_hash)
          rule_group.add_rule(rule)
        end
      end # bali_process_auth_rules

      # add can rule programatically
      def add_can(rule_group, *args)
        add :can, rule_group, *args
      end

      # add cant rule programatically
      def add_cant(rule_group, *args)
        add :cant, rule_group, *args
      end
    end
  end
end
