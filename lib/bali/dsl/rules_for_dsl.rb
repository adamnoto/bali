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
            Bali::Integrator::Rule.add(auth_val, self.current_rule_group, *args)
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
    Bali::Integrator::Rule.add_can(self.current_rule_group, *args)
  end

  def cant(*args)
    Bali::Integrator::Rule.add_cant(self.current_rule_group, *args)
  end

  def can_all
    Bali::Integrator::RuleGroup.make_zeus(self.current_rule_group)
  end

  def cant_all
    Bali::Integrator::RuleGroup.make_plant(self.current_rule_group)
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

end # class
