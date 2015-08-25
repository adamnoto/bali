require_relative 'spec_helper'

module My; end
class My::Transaction
  include Bali::Objector

  attr_accessor :is_settled
  attr_accessor :payment_channel

  alias :is_settled? :is_settled
end

class My::Employee
  include Bali::Objector

  # number of experience in the company
  attr_accessor :exp_years
  attr_accessor :roles
end
