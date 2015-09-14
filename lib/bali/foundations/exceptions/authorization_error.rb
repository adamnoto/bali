# Error that will be raised when subtarget cannot do something he wanted to do,
# or when subtarget do something he should not be allowed to do.
class Bali::AuthorizationError < Bali::Error
  attr_accessor :operation
  attr_accessor :auth_level
  attr_accessor :role

  # it may be nil, depends on whether rule checking is using symbol/user
  attr_accessor :subtarget

  # whether a class or an object
  attr_accessor :target

  def to_s
    "Role #{role} is performing #{operation} using precedence #{auth_level}"
  end
end
