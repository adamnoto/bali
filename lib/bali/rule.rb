# This class represents a rule.
#   can :delete
# A rule can also contains conditional part
class Bali::Rule
  # auth_val is either :can or :cant
  attr_reader :auth_val

  # what is the operation: create, update, delete, or any other
  attr_reader :operation

  # if decider is defined, a rule is executed only if decider evaluates to true
  attr_accessor :decider

  def initialize(auth_val, operation)
    self.auth_val = auth_val
    @operation = operation
    self
  end

  def clone
    cloned_rule = Bali::Rule.new(auth_val, operation)
    cloned_rule.decider = decider if decider

    cloned_rule
  end

  def auth_val=(aval)
    # TODO: in version 3 remove :cant
    if aval == :can || aval == :cant
      @auth_val = aval
    elsif aval == :cant
      @auth_val = :cant
    else
      raise Bali::DslError, "auth_val can only either be :can or :cant"
    end
  end

  def is_discouragement?
    auth_val == :cant
  end

  def has_decider?
    decider.is_a?(Proc)
  end
end
