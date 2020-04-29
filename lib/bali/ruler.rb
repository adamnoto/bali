# This class represents all roles, and its rules, for a resource
class Bali::Ruler
  attr_reader :model_class
  attr_accessor :roles

  private :model_class

  def self.for(record_class)
    rule_maker_cls_str = "#{record_class}#{Bali.config.suffix}"
    rule_class = rule_maker_cls_str.safe_constantize
    rule_class.ruler if rule_class
  end

  def initialize(model_class)
    @model_class = model_class
    @roles = {}
  end

  def << role
    @roles[role.name] = role
  end

  def [] role
    symbolized_role = role.to_sym if role
    @roles[symbolized_role]
  end
end
