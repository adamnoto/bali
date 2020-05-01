require "forwardable"

class Bali::Rules
  extend Bali::Statics::Authorizer
  extend Bali::Statics::ScopeRuler

  class << self
    extend Forwardable

    attr_writer :current_role
    attr_reader :ruler

    def_delegators :inheritable_role, :scope, :scope
    def_delegators :inheritable_role, :can, :can
    def_delegators :inheritable_role, :cant, :cant
    def_delegators :inheritable_role, :cant_all, :cant_all
    def_delegators :inheritable_role, :can_all, :can_all
  end

  def self.for(record_class)
    rule_maker_cls_str = "#{record_class}#{Bali.config.suffix}"
    rule_maker_cls_str.safe_constantize
  end

  def self.model_class
    class_name = to_s
    suffix = Bali.config.suffix
    rule_class_maker_str = class_name[0...class_name.length - suffix.length]
    rule_class_maker_str.constantize
  end

  def self.role(*role_names, &block)
    role_names.each do |role_name|
      if Bali::Role::IDENTIFIER_CLASSES.include?(role_name.class)
        role = ruler.find_or_create_role role_name
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
