# for internal use, representing one, single, atomic rule
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

  def auth_val=(aval)
    if aval == :can || aval == :cant
      @auth_val = aval
    else
      raise Bali::DslError, "auth_val can only either be :can or :cant"
    end
  end

  def is_discouragement?
    self.auth_val == :cant
  end

  def has_decider?
    self.decider.is_a?(Proc)
  end
end
