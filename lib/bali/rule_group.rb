class Bali::RuleGroup
  RIGHTS = [
    INHERIT = :inherit,
    DEFAULT_DENY = :default_deny,
    DEFAULT_ALLOW = :default_allow
  ].freeze

  # the target class
  attr_accessor :target

  # the user to which this rule group is applied
  attr_accessor :subtarget

  # what can be done and what cant be done
  attr_accessor :cans, :cants

  # if set to true then the subtarget, by default, can do everything
  attr_accessor :can_all
  alias :can_all? :can_all

  attr_accessor :right_level

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
    @right_level = INHERIT

    @cans = {}
    @cants = {}
  end

  def can_all?
    right_level == DEFAULT_ALLOW
  end

  def cant_all?
    right_level == DEFAULT_DENY
  end

  def can_all=(bool)
    case bool
    when true then @right_level = DEFAULT_ALLOW
    else @right_level = DEFAULT_DENY
    end
  end

  def add_rule(rule)
    # operation cant be defined twice
    operation = rule.operation.to_sym

    return if cants[operation] && cans[operation]

    if rule.term == :cant
      cants[operation] = rule
      cans.delete operation
    else
      cans[operation] = rule
      cants.delete operation
    end
  end

  def get_rule(term, operation)
    case term
    when :can then cans[operation.to_sym]
    when :cant then cants[operation.to_sym]
    end
  end

  def rules
    cans.values + cants.values
  end
end
