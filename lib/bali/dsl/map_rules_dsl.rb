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

  def describe(*params)
    raise Bali::DslError, "describe block must be within rules_for block"
  end
end
