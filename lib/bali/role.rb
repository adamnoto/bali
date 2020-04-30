class Bali::Role
  RIGHTS = [
    INHERIT = :inherit,
    DEFAULT_DENY = :default_deny,
    DEFAULT_ALLOW = :default_allow
  ].freeze

  attr_reader :name
  attr_reader :scope
  attr_accessor :cans, :cants

  attr_accessor :can_all
  alias :can_all? :can_all

  attr_accessor :right_level
  attr_reader :unscoped

  def self.formalize(object)
    case object
    when String, Symbol, NilClass then [object]
    when Array then object
    else formalize(extract_roles_from_object(object))
    end
  end

  def self.extract_roles_from_object(object)
    method_name = object.class.role_field_for_authorization

    method_name ?
      formalize(object.send(method_name)) :
      formalize(nil)
  end

  def initialize(name)
    @name = name.to_sym if name
    @right_level = INHERIT
    @unscoped = false

    @cans = {}
    @cants = {}
  end

  def can_all?
    right_level == DEFAULT_ALLOW
  end

  def cant_all?
    right_level == DEFAULT_DENY
  end

  def unscoped?
    @unscoped
  end

  ##### DSL METHODS
  def can(*args, &block)
    add :can, *args, block
  end

  def cant(*args, &block)
    add :cant, *args, block
  end

  def can_all
    @right_level = DEFAULT_ALLOW
  end

  def cant_all
    @right_level = DEFAULT_DENY
  end

  def add(term, *operations, block)
    operations.each do |operation|
      rule = Bali::Rule.new(term, operation)
      rule.conditional = block
      self << rule
    end
  end

  def scope(&block)
    @scope = block
  end

  def unscope
    @unscoped = true
  end
  ##### DSL METHODS

  def << rule
    operation = rule.operation.to_sym

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
