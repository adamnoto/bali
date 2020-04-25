# Error that will be raised when subtarget cant do something he wanted to do,
# or when subtarget do something he should not be allowed to do.
class Bali::AuthorizationError < Bali::Error
  attr_accessor :operation
  attr_accessor :auth_level
  attr_accessor :role

  # it may be nil, depends on whether rule checking is using symbol/user
  attr_accessor :subtarget

  # whether a class or an object
  attr_accessor :target

  def target_proper_class
    if target.is_a?(Class)
      target
    else
      target.class
    end
  end

  def to_s
    role = humanise_value(role)
    operation = humanise_value(operation)
    auth_level = humanise_value(auth_level)

    if auth_level == :can
      "Role #{role} is not allowed to perform operation `#{operation}` on #{target_proper_class}"
    else
      "Role #{role} is allowed to perform operation `#{operation}` on #{target_proper_class}"
    end
  end

  private
    def humanise_value(val)
      val.nil? ? "<nil>" : val
    end
end
