require_relative "bali/version"
require_relative "bali/rule_class"
require_relative "bali/rule_group"
require_relative "bali/rule"

require_relative "bali/objector"

# exception classes
require_relative "bali/exceptions/dsl_error"
module Bali
  # mapping class to a RuleClass
  RULE_CLASS_MAP = {}

  # from symbol to full class name
  ALIASED_RULE_CLASS_MAP = {}

  # from full class name to symbol
  REVERSE_ALIASED_RULE_CLASS_MAP = {}
end

module Bali
  extend self

  def rule_classes
    RULE_CLASS_MAP
  end

  def rule_class_for(target)
    if target.is_a?(Symbol)
      class_name = ALIASED_RULE_CLASS_MAP[target]
      raise Bali::DslError, "Rule class is not defined for: #{target}" if class_name.nil?

      rule_class_for(class_name)
    else
      rule_class = RULE_CLASS_MAP[target]
      raise Bali::DslError, "Rule class is not defined for: #{target}" if rule_class.nil?
      rule_class
    end
  end

  def rule_group_for(target_class, subtarget)
    rule_class = Bali.rule_class_for(target_class)
    rule_group = rule_class.rules_for(subtarget)
    
    rule_group
  end

  def add_rule_class(rule_class)
    if rule_class.is_a?(Bali::RuleClass)
      target = rule_class.target_class
      alias_target = rule_class.alias_name

      raise "Target must be a class" unless target.is_a?(Class)

      # remove any previous association of rule
      begin 
        last_associated_alias = Bali::REVERSE_ALIASED_RULE_CLASS_MAP[target]
        if last_associated_alias
          Bali::ALIASED_RULE_CLASS_MAP.delete(last_associated_alias)
          Bali::REVERSE_ALIASED_RULE_CLASS_MAP.delete(target)
          Bali::RULE_CLASS_MAP.delete(target)
        end
      end

      # if "as" is present
      if alias_target.is_a?(Symbol)
        Bali::ALIASED_RULE_CLASS_MAP[alias_target] = target
        Bali::REVERSE_ALIASED_RULE_CLASS_MAP[target] = alias_target
      end

      Bali::RULE_CLASS_MAP[target] = rule_class
    else
      raise "Only allow instance of Bali::RuleClass"
    end
  end # add_rule_class
end

module Bali
  class Bali::MapRulesDsl
    attr_accessor :current_rule_class

    def initialize
      @@lock = Mutex.new
    end

    def rules_for(target_class, target_alias_hash = {}, &block)
      @@lock.synchronize do
        self.current_rule_class = Bali::RuleClass.new(target_class)
        self.current_rule_class.alias_name = target_alias_hash[:as] || target_alias_hash["as"]

        Bali::MapRulesRulesForDsl.new(self).instance_eval(&block)

        # done processing the block, now add the rule class
        Bali.add_rule_class(self.current_rule_class)

        target_class.include(Bali::Objector) unless target_class.include?(Bali::Objector)
      end
    end
  end
end

module Bali
  class Bali::MapRulesRulesForDsl
    attr_accessor :map_rules_dsl
    attr_accessor :current_rule_group

    def initialize(map_rules_dsl)
      @@lock = Mutex.new
      self.map_rules_dsl = map_rules_dsl
    end

    def describe(subtarget, rules = {})
      target_class = self.map_rules_dsl.current_rule_class.target_class
      target_alias = self.map_rules_dsl.current_rule_class.alias_name
      @@lock.synchronize do
        rule_group = Bali::RuleGroup.new(target_class, target_alias, subtarget)
        self.current_rule_group = rule_group

        if block_given?
          the_object = Object.new
          # the_object would be the record, or the object of class as specified
          # in rules_for
          yield the_object
        else
          # auth_val is either can or cant
          rules.each do |auth_val, operations|
            if operations.is_a?(Array)
              operations.each do |op|
                rule = Bali::Rule.new(auth_val, op)
                rule_group.add_rule(rule)
              end
            else
              operation = operations # well, basically is 1 only
              rule = Bali::Rule.new(auth_val, operation) 
              rule_group.add_rule(rule)
            end
          end # each rules
        end # block_given?

        # add current_rule_group
        self.map_rules_dsl.current_rule_class.add_rule_group(rule_group)
      end # mutex synchronize
    end # describe


    def process_auth_rules(auth_val, operations)
      conditional_hash = nil
      
      # scan opreation for hash
      operations.each do |elm|
        if elm.is_a?(Hash)
          conditional_hash = elm
        end
      end

      if conditional_hash
        op = operations[0]
        rule = Bali::Rule.new(auth_val, op)
        rule.decider = conditional_hash[:if] || conditional_hash["if"]
        self.current_rule_group.add_rule(rule)
      else
        # no conditional hash, proceed adding operations one by one
        operations.each do |op|
          rule = Bali::Rule.new(auth_val, op)
          self.current_rule_group.add_rule(rule)
        end
      end
    end # process_auth_rules

    def can(*operations)
      process_auth_rules(:can, operations)
    end

    def cant(*operations)
      process_auth_rules(:cant, operations)
    end

    def can_all
      self.current_rule_group.zeus = true
      self.current_rule_group.plant = false
    end

    def cant_all
      self.current_rule_group.plant = true
      self.current_rule_group.zeus = false
    end

  end # class
end # module

module Bali
  extend self
  def map_rules(&block)
    dsl_map_rules = Bali::MapRulesDsl.new
    dsl_map_rules.instance_eval(&block)
  end

  def clear_rules
    Bali::RULE_CLASS_MAP.clear
    Bali::REVERSE_ALIASED_RULE_CLASS_MAP.clear
    Bali::ALIASED_RULE_CLASS_MAP.clear
    true
  end
end
