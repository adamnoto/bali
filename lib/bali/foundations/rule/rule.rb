# for internal use, representing one, single, atomic rule
class Bali::Rule
  # auth_val is either :can or :cannot
  attr_reader :auth_val

  # what is the operation: create, update, delete, or any other
  attr_reader :operation

  # if decider is defined, a rule is executed only if decider evaluates to true
  attr_accessor :decider
  # either unless or if
  attr_reader :decider_type

  def initialize(auth_val, operation)
    self.auth_val = auth_val
    @operation = operation
    self
  end

  def auth_val=(aval)
    # TODO: in version 3 remove :cant
    if aval == :can || aval == :cannot
      @auth_val = aval
    elsif aval == :cant
      @auth_val = :cannot
    else
      raise Bali::DslError, "auth_val can only either be :can or :cannot"
    end
  end

  def decider_type=(dectype)
    if dectype == :if || dectype == :unless
      @decider_type = dectype
    else
      raise Bali::DslError, "decider type can only be either if or unless"
    end
  end

  def is_discouragement?
    # TODO: in version 3.0 remove :cant
    self.auth_val == :cannot || self.auth_val == :cant
  end

  def has_decider?
    raise Bali::DslError, "has decider but not sure if it is if or unless type decider" if self.decider.is_a?(Proc) && self.decider_type.nil?
    self.decider.is_a?(Proc)
  end
end
