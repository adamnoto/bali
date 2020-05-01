# This class represents all roles, and its rules, for a resource
class Bali::Ruler
  attr_reader :model_class
  attr_accessor :roles

  private :model_class

  def self.for(record_class)
    rule_class = Bali::Rules.for(record_class)
    rule_class.ruler if rule_class
  end

  def initialize(model_class)
    @model_class = model_class
    @roles = {}
    @roles[nil] = Bali::Role.new(nil)
  end

  def << role
    @roles[role.name] = role
  end

  def [] role
    symbolized_role = role.to_sym if role
    @roles[symbolized_role]
  end
end
