# This class represents all roles, and its rules, for a resource
class Bali::Ruler
  attr_reader :model_class
  attr_accessor :roles

  private :model_class

  def self.for(record_class)
    rule_class = Bali::RULE_CLASS_MAP[record_class.to_s]

    if rule_class.nil?
      rule_class_maker_str = record_class.to_s + Bali.config.suffix
      rule_class_maker = rule_class_maker_str.safe_constantize

      if rule_class_maker && rule_class_maker.ancestors.include?(Bali::Rules)
        rule_class = rule_class_maker.ruler
        Bali::RULE_CLASS_MAP[record_class.to_s] = rule_class
      end
    end

    rule_class
  end

  def initialize(model_class)
    @model_class = model_class
    @roles = {}
  end

  def << role
    @roles[role.subtarget] = role
  end

  def [] role
    @roles[role&.to_sym]
  end
end
