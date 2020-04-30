class Transaction < ActiveRecord::Base
  alias :settled? :is_settled
  belongs_to :user
end
