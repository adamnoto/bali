# this class is used to define DSL after rules_for is invoked.
# @author Adam Pahlevi Baihaqi
class Bali::RulesForDsl
  attr_accessor :map_rules_dsl
  attr_accessor :current_rule_group

  def initialize(map_rules_dsl)
    @@lock = Mutex.new
    self.map_rules_dsl = map_rules_dsl
  end

  def current_rule_class
    self.map_rules_dsl.current_rule_class
  end

  def describe(*params)
    @@lock.synchronize do
      subtargets = []
      rules = {}

      params.each do |passed_argument|
        if passed_argument.is_a?(Symbol) || passed_argument.is_a?(String)
          subtargets << passed_argument
        elsif passed_argument.is_a?(NilClass)
          subtargets << passed_argument
        elsif passed_argument.is_a?(Array)
          subtargets += passed_argument
        elsif passed_argument.is_a?(Hash)
          rules = passed_argument
        else
          raise Bali::DslError, "Allowed argument for describe: symbol, string, nil and hash"
        end
      end

      target_class = self.map_rules_dsl.current_rule_class.target_class

      subtargets.each do |subtarget|
        rule_group = self.current_rule_class.rules_for(subtarget)
        if rule_group.nil?
          rule_group = Bali::RuleGroup.new(target_class, subtarget)
        end

        self.current_rule_group = rule_group

        if block_given?
          yield
        else
          # auth_val is either can or cant
          rules.each do |auth_val, operations|
            if operations.is_a?(Array)
              operations.each do |op|
                rule = Bali::Rule.new(auth_val, op)
                self.current_rule_group.add_rule(rule)
              end
            else
              operation = operations # well, basically is 1 only
              rule = Bali::Rule.new(auth_val, operation)
              self.current_rule_group.add_rule(rule)
            end
          end # each rules
        end # block_given?

        # add current_rule_group
        self.map_rules_dsl.current_rule_class.add_rule_group(self.current_rule_group)
      end # each subtarget
    end # sync block
  end # describe

  # others block
  def others(*params)
    @@lock.synchronize do
      rules = {}

      params.each do |passed_argument|
        if passed_argument.is_a?(Hash)
          rules = passed_argument
        else
          raise Bali::DslError, "Allowed argument for others: hash"
        end
      end

      self.current_rule_group  = self.map_rules_dsl.current_rule_class.others_rule_group

      if block_given?
        yield
      else
        rules.each do |auth_val, operations|
          if operations.is_a?(Array)
            operations.each do |op|
              rule = Bali::Rule.new(auth_val, op)
              self.current_rule_group.add_rule(rule)
            end
          else
            operation = operations
            rule = Bali::Rule.new(auth_val, operation)
            self.current_rule_group.add_rule(rule)
          end
        end # each rules
      end # block_given?
    end # synchronize
  end # others

  # to define can and cant is basically using this method
  def bali_process_auth_rules(auth_val, operations)
    conditional_hash = nil

    # scan operations for options
    operations.each do |elm|
      if elm.is_a?(Hash)
        conditional_hash = elm
      end
    end

    if conditional_hash
      op = operations[0]
      rule = Bali::Rule.new(auth_val, op)
      if conditional_hash[:if] || conditional_hash["if"]
        rule.decider = conditional_hash[:if] || conditional_hash["if"]
        rule.decider_type = :if
      elsif conditional_hash[:unless] || conditional_hash[:unless]
        rule.decider = conditional_hash[:unless] || conditional_hash["unless"]
        rule.decider_type = :unless
      end
      self.current_rule_group.add_rule(rule)
    else
      # no conditional hash, proceed adding operations one by one
      operations.each do |op|
        rule = Bali::Rule.new(auth_val, op)
        self.current_rule_group.add_rule(rule)
      end
    end
  end # bali_process_auth_rules

  # clear all defined rules
  def clear_rules
    self.current_rule_group.clear_rules
    self.current_rule_class.others_rule_group.clear_rules
    true
  end

  def can(*operations)
    bali_process_auth_rules(:can, operations)
  end

  def cannot(*operations)
    bali_process_auth_rules(:cannot, operations)
  end

  def cant(*operations)
    puts "Deprecation Warning: declaring rules with cant will be deprecated on major release 3.0, use cannot instead"
    cannot(*operations)
  end

  def can_all
    self.current_rule_group.zeus = true
    self.current_rule_group.plant = false
  end

  def cannot_all
    self.current_rule_group.plant = true
    self.current_rule_group.zeus = false
  end

  def cant_all
    puts "Deprecation Warning: declaring rules with cant_all will be deprecated on major release 3.0, use cannot_all instead"
    cannot_all
  end
end # class
