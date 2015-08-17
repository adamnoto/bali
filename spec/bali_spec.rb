require_relative 'spec_helper'

module My; end
class My::Transaction
  attr_accessor :is_settled
  attr_accessor :payment_channel

  alias :is_settled? :is_settled
end
