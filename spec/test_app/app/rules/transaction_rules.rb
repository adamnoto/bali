class TransactionRules < Bali::Rules
  can :update, :unsettle
  can :print

  scope do |data, current_user|
    unless current_user.role == "admin"
      data.where(user_id: current_user.id)
    end
  end

  # overwrites :unsettle
  can :unsettle do |record|
    record.settled?
  end

  # will inherit update, and print
  role :supervisor, :accountant do
    can :unsettle
  end

  role :accountant do
    cant :update
  end

  role :supervisor do
    can :comment
  end

  role :clerk do
    cant_all
    can :unsettle
  end

  role :admin do
    can_all
  end
end
