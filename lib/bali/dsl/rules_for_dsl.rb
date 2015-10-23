# this class is used to define DSL after rules_for is invoked.
# @author Adam Pahlevi Baihaqi
class Bali::RulesForDsl
  attr_accessor :map_rules_dsl
  attr_accessor :current_rule_group

  # all to be processed subtargets
  attr_accessor :current_subtargets
  # rules defined with hash can: [] and cannot: []
  attr_accessor :shortcut_rules

  def initialize(map_rules_dsl)
    @@lock = Mutex.new
    self.map_rules_dsl = map_rules_dsl
  end

  def current_rule_class
    self.map_rules_dsl.current_rule_class
  end
  protected :current_rule_class

  def role(*params)
    @@lock.synchronize do
      bali_scrap_actors(*params)
      bali_scrap_shortcut_rules(*params)
      current_subtargets.each do |subtarget|
        if block_given?
          bali_process_subtarget(subtarget) do
            yield
          end
        else
          bali_process_subtarget(subtarget)
        end
      end
    end
  end # role

  def describe(*params)
    puts "Bali Deprecation Warning: describing rules using describe will be deprecated on major release 3.0, use role instead"
    if block_given?
      role(*params) do
        yield
      end
    else
      role(*params)
    end
  end

  # others block
  def others(*params)
    if block_given?
      role("__*__") do
        yield
      end
    end
  end # others

  # clear all defined rules
  def clear_rules
    self.current_rule_group.clear_rules
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
  
  private
    def bali_scrap_actors(*params)
      self.current_subtargets = []
      params.each do |passed_argument|
        if passed_argument.is_a?(Symbol) || passed_argument.is_a?(String)
          self.current_subtargets << passed_argument
        elsif passed_argument.is_a?(NilClass)
          self.current_subtargets << passed_argument
        elsif passed_argument.is_a?(Array)
          self.current_subtargets += passed_argument
        end
      end
      nil
    end

    def bali_scrap_shortcut_rules(*params)
      self.shortcut_rules = {}
      params.each do |passed_argument|
        if passed_argument.is_a?(Hash)
          self.shortcut_rules = passed_argument
        end
      end
      nil
    end

    def bali_process_subtarget(subtarget)
      target_class = self.map_rules_dsl.current_rule_class.target_class
      rule_class = self.map_rules_dsl.current_rule_class

      rule_group = rule_class.rules_for(subtarget)

      if rule_group.nil?
        rule_group = Bali::RuleGroup.new(target_class, subtarget)
      end

      self.current_rule_group = rule_group

      if block_given?
        yield
      else
        # auth_val is either can or cannot
        shortcut_rules.each do |auth_val, operations|
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
      rule_class.add_rule_group(rule_group)

      nil
    end

    # to define can and cant is basically using this method
    def bali_process_auth_rules(auth_val, args)
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
        bali_embed_conditions(rule, conditional_hash)
        self.current_rule_group.add_rule(rule)
      end
    end # bali_process_auth_rules

    # process conditional statement in rule definition
    def bali_embed_conditions(rule, conditional_hash = nil)
      return if conditional_hash.nil?

      condition_type = conditional_hash.keys[0].to_s.downcase
      condition_type_symb = condition_type.to_sym

      if condition_type_symb == :if || condition_type_symb == :unless
        rule.decider = conditional_hash.values[0]
        rule.decider_type = condition_type_symb
      end
      nil
    end
end # class
