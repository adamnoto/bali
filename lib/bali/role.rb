class Bali::Role
  RIGHTS = [
    INHERIT = :inherit,
    DEFAULT_DENY = :default_deny,
    DEFAULT_ALLOW = :default_allow
  ].freeze

  attr_accessor :subtarget
  attr_accessor :cans, :cants

  attr_accessor :can_all
  alias :can_all? :can_all

  attr_accessor :right_level

  def self.formalize(object)
    case object
    when String then [object]
    when Symbol then [object]
    when NilClass then [object]
    when Array then object
    else
      kls_name = object.class.to_s
      method_name = Bali::TRANSLATED_SUBTARGET_ROLES[kls_name]
      roles = method_name ? formalize(object.send(method_name)) : formalize(nil)

      roles
    end
  end

  def initialize(subtarget)
    @subtarget = subtarget&.to_sym
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

  def << rule
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

  def find_rule(term, operation)
    case term
    when :can then cans[operation.to_sym]
    when :cant then cants[operation.to_sym]
    end
  end

  def rules
    cans.values + cants.values
  end
end
