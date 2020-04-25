# module that will be included in each instantiated target classes as defined
# in map_rules
module Bali::Objector
  def self.included(base)
    base.extend Bali::Objector::Statics
  end

  def can?(actor_or_roles, operation = nil)
    self.class.can?(actor_or_roles, operation, self)
  end

  def cant?(actor_or_roles, operation = nil)
    self.class.cant?(actor_or_roles, operation, self)
  end
end

# to allow class-level objection
module Bali::Objector::Statics
  def can?(actor_or_roles, operation, record = self)
    Bali::Judge.check(:can, actor_or_roles, operation, record)
  end

  def cant?(actor_or_roles, operation, record = self)
    Bali::Judge.check(:cant, actor_or_roles, operation, record)
  end
end
