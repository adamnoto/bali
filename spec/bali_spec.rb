require_relative "./models/transaction"
require_relative "./models/user"
require_relative "./rules/transaction_rules"
require_relative "./rules/user_rules"

Bali.configure do |config|
  config.rules_path = File.expand_path(__FILE__ + "/../rules/")
end

module My
  class Transaction
    include Bali::Authorizer

    attr_accessor :is_settled

    alias :is_settled? :is_settled
    alias :settled= :is_settled=
  end

  class SecuredTransaction < My::Transaction
  end

  class Employee
    include Bali::Authorizer

    # number of experience in the company
    attr_accessor :exp_years
    attr_accessor :roles
  end
end
