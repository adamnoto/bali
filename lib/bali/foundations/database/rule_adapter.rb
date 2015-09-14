class Bali::Database::RuleAdapter
  # get all defined rules through this adapter
  def get_all
    raise Bali::Error, "get_all is not yet defined/overridden"
  end

  # adding rule
  def add(rule)
    raise Bali::Error, "add is not yet defined/overridden"
  end

  # editing old rule with the new one, given the same auth_val and operation
  # as defined in the rule
  def edit(rule)
    raise Bali::Error, "edit is not yet defined/overridden"
  end

  # adding role, options is a hash that contains :to
  def add_role(role_name, options = {})
    raise Bali::Error, "add_role is not yet defined/overridden"
  end

  # removing role, options is a hash that contains :from
  def remove_role(role_name, options = {})
    raise Bali::Error, "remove_role is not yet defined/overridden"
end
