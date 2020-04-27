class Transaction
  include Bali::Authorizer

  attr_accessor :is_settled

  alias :settled? :is_settled
  alias :settled= :is_settled=
end
