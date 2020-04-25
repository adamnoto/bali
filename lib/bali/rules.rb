class Bali::Rules
  class << self
    attr_writer :current_rule_group
    attr_accessor :current_rule_class
  end

  def self.model_class
    class_name = to_s
    suffix = Bali.config.suffix
    rule_class_maker_str = class_name[0...class_name.length - suffix.length]
    rule_class_maker_str.constantize
  end

  def self.can(*args, &block)
    add :can, *args, block
  end

  def self.cant(*args, &block)
    add :cant, *args, block
  end

  def self.cant_all(*args)
    current_rule_group.can_all = false
  end

  def self.can_all(*args)
    current_rule_group.can_all = true
  end

  def self.role(*roles)
    roles.each do |role|
      if Symbol === role || String === role || NilClass === role
        set_role role
        yield
      else
        raise Bali::DslError, "Cannot define role using #{param.class}. " +
          "Please use either a Symbol, a String or nil"
      end
    end
  end

  def self.current_rule_group
    @current_rule_group ||= set_role "__*__"
  end

  def self.current_rule_class
    @current_rule_class ||= begin
      rule_class = Bali::RuleClass.new(model_class)
      Bali::Integrator::RuleClass.add(rule_class)
      rule_class
    end
  end

  def self.set_role(role)
    rule_group = current_rule_class.rules_for(role) ||
      Bali::RuleGroup.new(model_class, role)

    current_rule_class.add_rule_group rule_group
    @current_rule_group = rule_group
  end

  def self.add(term, *operations, block)
    operations.each do |operation|
      rule = Bali::Rule.new(term, operation)
      rule.conditional = block if block
      current_rule_group.add_rule(rule)
    end
  end

end
