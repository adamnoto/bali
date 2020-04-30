class TransactionRules < Bali::Rules
  can :update, :unsettle
  can :print

  # redefine :delete
  can :unsettle do |record|
    record.settled?
  end

  # will inherit update, and print
  role :supervisor, :accountant do
    unscope
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
    unscope
    can_all
  end
end
