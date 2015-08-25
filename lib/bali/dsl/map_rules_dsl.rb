# grand scheme of things begin here
class Bali::MapRulesDsl
  attr_accessor :current_rule_class

  def initialize
    @@lock = Mutex.new
  end

  def rules_for(target_class, target_alias_hash = {}, &block)
    @@lock.synchronize do
      self.current_rule_class = Bali::RuleClass.new(target_class)
      self.current_rule_class.alias_name = target_alias_hash[:as] || target_alias_hash["as"]

      Bali::RulesForDsl.new(self).instance_eval(&block)

      # done processing the block, now add the rule class
      Bali.add_rule_class(self.current_rule_class)
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
end
