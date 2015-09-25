# grand scheme of things begin here
class Bali::MapRulesDsl
  attr_accessor :current_rule_class

  def initialize
    @@lock = Mutex.new
  end

  # defining rules
  def rules_for(target_class, options_hash = {}, &block)
    @@lock.synchronize do
      raise Bali::DslError "rules_for must describe a target which is a class" unless target_class.is_a?(Class)
      self.current_rule_class = Bali::RuleClass.new(target_class)

      parent_class = options_hash[:inherits] || options_hash["inherits"]
      if parent_class 
        # in case there is inherits specification
        raise Bali::DslError, "inherits must take a class" unless parent_class.is_a?(Class)
        rule_class_from_parent = Bali::Integrators::Rule.rule_class_for(parent_class)
        raise Bali::DslError, "not yet defined a rule class for #{parent_class}" if rule_class_from_parent.nil?
        self.current_rule_class = rule_class_from_parent.clone(target_class: target_class)
      end

      Bali::RulesForDsl.new(self).instance_eval(&block)

      # done processing the block, now add the rule class
      Bali::Integrators::Rule.add_rule_class(self.current_rule_class)
    end
  end

  # subtarget_class is the subtarget's class definition
  # field_name is the field that will be consulted when instantiated object of this class is passed in can? or cant?
  def roles_for(subtarget_class, field_name)
    raise Bali::DslError, "Subtarget must be a class" unless subtarget_class.is_a?(Class)
    raise Bali::DslError, "Field name must be a symbol/string" if !(field_name.is_a?(Symbol) || field_name.is_a?(String))

    Bali::TRANSLATED_SUBTARGET_ROLES[subtarget_class.to_s] = field_name
    nil
  end

  def describe(*params)
    raise Bali::DslError, "describe block must be within rules_for block"
  end

  def can(*params)
    raise Bali::DslError, "can block must be within describe block"
  end

  def cant(*params)
    puts "Deprecation Warning: declaring rules with cant will be deprecated on major release 3.0, use cannot instead"
    cannot *params
  end

  def cannot(*params)
    raise Bali::DslError, "cant block must be within describe block"
  end

  def can_all(*params)
    raise Bali::DslError, "can_all block must be within describe block"
  end

  def clear_rules
    raise Bali::DslError, "clear_rules must be called within describe block"
  end

  def cant_all(*params)
    puts "Deprecation Warning: declaring rules with cant_all will be deprecated on major release 3.0, use cannot instead"
    cannot_all *params
  end

  def cannot_all(*params)
    raise Bali::DslError, "cant_all block must be within describe block"
  end
end
