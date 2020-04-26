class Bali::Rules
  class << self
    attr_writer :current_role
    attr_reader :ruler
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
    current_role.can_all = false
  end

  def self.can_all(*args)
    current_role.can_all = true
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

  def self.current_role
    @current_role ||= set_role nil
  end

  def self.ruler
    @ruler ||= Bali::Ruler.new(model_class)
  end

  def self.set_role(role)
    role = ruler[role] || Bali::Role.new(role)
    ruler << role
    @current_role = role
  end

  def self.add(term, *operations, block)
    operations.each do |operation|
      rule = Bali::Rule.new(term, operation)
      rule.conditional = block if block
      current_role << rule
    end
  end

end
