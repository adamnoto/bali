class TransactionsController < ApplicationController
  def index
    user_id = params.fetch(:user_id)
    @current_user = User.find(user_id)

    def current_user
      @current_user
    end

    @all_transactions = Transaction.all
    @scoped_transactions = rule_scope(@all_transactions)
    render file: Rails.root.join("app/views/transactions/index")
  end
end
