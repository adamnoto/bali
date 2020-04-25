class Bali::RuleGroup
  # the target class
  attr_accessor :target

  # the user to which this rule group is applied
  attr_accessor :subtarget

  # what can be done and what cant be done
  attr_accessor :cans, :cants

  # if set to true then the subtarget can do anything
  attr_accessor :can_all
  alias :can_all? :can_all

  # allowing "general user" and :general_user to route to the same rule group
  def self.canon_name(subtarget)
    if subtarget.is_a?(String)
      return subtarget.gsub(" ", "_").to_sym
    else
      return subtarget
    end
  end

  def initialize(target, subtarget)
    @target = target
    @subtarget = Bali::RuleGroup.canon_name(subtarget)

    @cans = {}
    @cants = {}
    @can_all = false
  end

  def clone
    cloned_rg = Bali::RuleGroup.new(target, subtarget)
    cans.each_value { |can_rule| cloned_rg.add_rule(can_rule.clone) }
    cants.each_value { |cant_rule| cloned_rg.add_rule(cant_rule.clone) }
    cloned_rg.can_all = can_all

    cloned_rg
  end

  def add_rule(rule)
    # operation cant be defined twice
    operation = rule.operation.to_sym

    return if cants[operation] && cans[operation]

    if rule.is_discouragement?
      cants[operation] = rule
      cans.delete operation
    else
      cans[operation] = rule
      cants.delete operation
    end
  end

  def clear_rules
    @cans = {}
    @cants = {}
  end

  def get_rule(auth_val, operation)
    rule = nil
    case auth_val
    when :can, "can"
      rule = cans[operation.to_sym]
    when :cant, "cant"
      rule = cants[operation.to_sym]
    else
      raise Bali::DslError, "Undefined operation: #{auth_val}"
    end

    rule
  end

  # all rules
  def rules
    cans.values + cants.values
  end
end
