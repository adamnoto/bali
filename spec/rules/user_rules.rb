class UserRules < Bali::Rules
  can :see_timeline do |record, actor|
    record.friends.include? actor
  end

  can :sign_in do
    User.no_more_beta?
  end
end
