# this class is used to define DSL after rules_for is invoked.
# @author Adam Pahlevi Baihaqi
class Bali::Dsl::RulesForDsl
  attr_accessor :map_rules_dsl
  attr_accessor :current_rule_group

  # all to be processed subtargets
  attr_accessor :current_subtargets

  def initialize(map_rules_dsl)
    @@lock ||= Mutex.new
    self.map_rules_dsl = map_rules_dsl
  end

  def current_rule_class
    self.map_rules_dsl.current_rule_class
  end
  protected :current_rule_class

  def role(*params)
    @@lock.synchronize do
      bali_scrap_actors(*params)
      current_subtargets.each do |subtarget|
        bali_set_subtarget(subtarget)

        if block_given?
          yield
        else
          # if no block, then rules are defined using shortcut notation, eg:
          # role :user, can: [:edit]
          # the last element of which params must be a hash
          shortcut_rules = params[-1]
          unless shortcut_rules.is_a?(Hash)
            raise Bali::DslError, "Pass a hash for shortcut notation"
          end

          shortcut_can_rules = shortcut_rules[:can] || shortcut_rules["can"]
          shortcut_cant_rules = shortcut_rules[:cant] || shortcut_rules["cant"]

          shortcut_rules.each do |auth_val, args|
            add(auth_val, self.current_rule_group, *args)
          end # each shortcut rules
        end # whether block is given or not
      end # each subtarget
    end # sync
  end # role

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

  def can(*args)
    add_can(self.current_rule_group, *args)
  end

  def cant(*args)
    add_cant(self.current_rule_group, *args)
  end

  def can_all
    bali_set_subtarget("__*__") if current_rule_group.nil?

    current_rule_group.zeus = true
    current_rule_group.plant = false
  end

  def cant_all
    bali_set_subtarget("__*__") if current_rule_group.nil?

    current_rule_group.plant = true
    current_rule_group.zeus = false
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

    # set the current processing on a specific subtarget
    def bali_set_subtarget(subtarget)
      rule_class = self.map_rules_dsl.current_rule_class
      target_class = rule_class.target_class

      rule_group = rule_class.rules_for(subtarget)

      if rule_group.nil?
        rule_group = Bali::RuleGroup.new(target_class, subtarget)
      end

      rule_class.add_rule_group rule_group
      self.current_rule_group = rule_group
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
        embed_condition(rule, conditional_hash)

        if rule_group.nil?
          bali_set_subtarget("__*__")
          rule_group = current_rule_group
        end

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

    # process conditional statement in rule definition
    # conditional hash: {if: proc} or {unless: proc}
    def embed_condition(rule, conditional_hash = nil)
      return if conditional_hash.nil?

      condition_type = conditional_hash.keys[0].to_s.downcase
      condition_type_symb = condition_type.to_sym

      if condition_type_symb == :if
        rule.decider = conditional_hash.values[0]
      end
      nil
    end

end # class
