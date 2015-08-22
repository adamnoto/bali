# this class is used to define DSL after rules_for is invoked.
# @author Adam Pahlevi Baihaqi
class Bali::RulesForDsl
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

  # to define can and cant is basically using this method
  def process_auth_rules(auth_val, operations)
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
