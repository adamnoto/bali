class Transaction
  include Bali::Objector

  attr_accessor :is_settled
  attr_accessor :payment_channel

  alias :settled? :is_settled
  alias :settled= :is_settled=
end
