# this class is used to define DSL after rules_for is invoked.
# @author Adam Pahlevi Baihaqi
class Bali::RulesForDsl
  attr_accessor :map_rules_dsl
  attr_accessor :current_rule_group

  # all to be processed subtargets
  attr_accessor :current_subtargets

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
            raise Bali::DslError, "Passin hash as arguments for shortcut notation"
          end

          shortcut_can_rules = shortcut_rules[:can] || shortcut_rules["can"]
          shortcut_cannot_rules = shortcut_rules[:cannot] || shortcut_rules["cannot"]

          shortcut_rules.each do |auth_val, args|
            Bali::Integrator::Rule.add(auth_val, self.current_rule_group, *args)
          end # each shortcut rules
        end # whether block is given or not
      end # each subtarget
    end # sync
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

  def can(*args)
    Bali::Integrator::Rule.add_can(self.current_rule_group, *args)
  end

  def cannot(*args)
    Bali::Integrator::Rule.add_cannot(self.current_rule_group, *args)
  end

  def cant(*operations)
    puts "Deprecation Warning: declaring rules with cant will be deprecated on major release 3.0, use cannot instead"
    cannot(*operations)
  end

  def can_all
    Bali::Integrator::RuleGroup.make_zeus(self.current_rule_group)
  end

  def cannot_all
    Bali::Integrator::RuleGroup.make_plant(self.current_rule_group)
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
