class Transaction < ActiveRecord::Base
  attr_accessor :is_settled

  alias :settled? :is_settled
  alias :settled= :is_settled=
end
