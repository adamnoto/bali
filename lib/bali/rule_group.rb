class Bali::RuleGroup
  # the target class
  attr_accessor :target

  # the user to which this rule group is applied
  attr_accessor :subtarget

  # what can be done and what cant be done
  attr_accessor :cans, :cants

  # if set to true then the subtarget can do anything
  attr_accessor :zeus
  alias :zeus? :zeus

  # if set to true, well, cant do anything
  attr_accessor :plant
  alias :plant? :plant

  # allowing "general user" and :general_user to route to the same rule group
  def self.canon_name(subtarget)
    if subtarget.is_a?(String)
      return subtarget.gsub(" ", "_").to_sym
    else
      return subtarget
    end
  end

  def initialize(target, subtarget)
    self.target = target
    self.subtarget = Bali::RuleGroup.canon_name(subtarget)

    self.cans = {}
    self.cants = {}

    # by default, rule group is neither zeus nor plant
    # it is neutral.
    # meaning, it is neither allowed to do everything, nor it is
    # prohibited to do anything. neutral.
    self.zeus = false
    self.plant = false
  end

  def clone
    cloned_rg = Bali::RuleGroup.new(target, subtarget)
    cans.each_value { |can_rule| cloned_rg.add_rule(can_rule.clone) }
    cants.each_value { |cant_rule| cloned_rg.add_rule(cant_rule.clone) }
    cloned_rg.zeus = zeus
    cloned_rg.plant = plant

    cloned_rg
  end

  def add_rule(rule)
    # operation cant be defined twice
    operation = rule.operation.to_sym

    return if self.cants[operation] && self.cans[operation]

    if rule.is_discouragement?
      self.cants[operation] = rule
      self.cans.delete operation
    else
      self.cans[operation] = rule
      self.cants.delete operation
    end
  end

  def clear_rules
    self.cans = {}
    self.cants = {}
  end

  def get_rule(auth_val, operation)
    rule = nil
    case auth_val
    when :can, "can"
      rule = self.cans[operation.to_sym]
    when :cant, "cant"
      rule = self.cants[operation.to_sym]
    else
      raise Bali::DslError, "Undefined operation: #{auth_val}"
    end

    rule
  end

  # all rules
  def rules
    self.cans.values + self.cants.values
  end
end