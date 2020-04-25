# This class represents a rule.
#   can :delete
# A rule can also contains conditional part
class Bali::Rule
  attr_reader :term
  attr_reader :operation
  attr_accessor :conditional

  def initialize(term, operation)
    self.term = term
    @operation = operation
    self
  end

  def clone
    cloned_rule = Bali::Rule.new(term, operation)
    cloned_rule.conditional = conditional

    cloned_rule
  end

  def term=(aval)
    # TODO: in version 3 remove :cant
    if aval == :can || aval == :cant
      @term = aval
    elsif aval == :cant
      @term = :cant
    else
      raise Bali::DslError, "term can only either be :can or :cant"
    end
  end

  def is_discouragement?
    term == :cant
  end

  def conditional?
    @is_conditional ||= !!conditional
  end
end
