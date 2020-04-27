module Bali::Statics::Authorizer
  def can?(actor_or_roles, operation, record = self)
    Bali::Judge.check(:can, actor_or_roles, operation, record)
  end

  def cant?(actor_or_roles, operation, record = self)
    Bali::Judge.check(:cant, actor_or_roles, operation, record)
  end
end
