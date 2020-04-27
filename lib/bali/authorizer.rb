module Bali::Authorizer
  def self.included(base)
    base.extend Bali::Authorizer::Statics
  end

  def can?(actor_or_roles, operation = nil)
    self.class.can?(actor_or_roles, operation, self)
  end

  def cant?(actor_or_roles, operation = nil)
    self.class.cant?(actor_or_roles, operation, self)
  end
end
