# This class represents a rule.
#   can :delete
# A rule can also contains conditional part
class Bali::Rule
  attr_reader :term
  attr_reader :operation
  attr_accessor :conditional

  def initialize(term, operation)
    @term = term
    @operation = operation
  end

  def conditional?
    @is_conditional ||= !!conditional
  end
end
