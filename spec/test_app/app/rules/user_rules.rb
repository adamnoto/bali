class UserRules < Bali::Rules
  can :see_timeline do |record, actor|
    record.friends.include? actor
  end

  can :sign_in do |record, actor|
    actor ? false : User.no_more_beta?
  end

  can :send_message do
    User.no_more_beta?
  end

  cant :see_banner do
    User.no_more_beta?
  end
end
