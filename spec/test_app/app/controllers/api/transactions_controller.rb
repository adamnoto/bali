module Api
  class TransactionsController < ActionController::API
    def index
      user = User.find params[:user_id]
      transactions = rule_scope(Transaction.all, user)
      render plain: transactions.pluck(:id).sort.join(", ")
    end
  end
end
