class Bali::Rules
  extend Bali::Statics::Authorizer

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
    inheritable_role.add :can, *args, block
  end

  def self.cant(*args, &block)
    inheritable_role.add :cant, *args, block
  end

  def self.cant_all(*args)
    inheritable_role.can_all = false
  end

  def self.can_all(*args)
    inheritable_role.can_all = true
  end

  def self.role(*role_names, &block)
    role_names.each do |role_name|
      if Symbol === role_name || String === role_name || NilClass === role_name
        role = ruler[role_name]

        if role.nil?
          role = Bali::Role.new(role_name)
          ruler << role
        end

        role.instance_eval(&block)
      else
        raise Bali::DslError, "Cannot define role using #{param.class}. " +
          "Please use either a Symbol, a String or nil"
      end
    end
  end

  def self.ruler
    @ruler ||= Bali::Ruler.new(model_class)
  end

  def self.inheritable_role
    ruler[nil]
  end
end
