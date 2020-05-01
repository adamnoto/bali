module Bali::Statics::ScopeRuler
  module HelperFunctions
    extend self

    def extract_data_and_actor(obj, arg1, arg2 = nil)
      if arg2.nil?
        data = arg1
        if obj.respond_to?(:current_user)
          actor = obj.current_user
        end
      else
        data, actor = arg1, arg2
      end

      return data, actor
    end

    def scope_for(relation)
      rule_class = Bali::Rules.for(relation.model)
      return unless rule_class

      rule_class.inheritable_role.scope
    end
  end

  def rule_scope(arg1, arg2 = nil)
    data, actor = HelperFunctions.extract_data_and_actor(self, arg1, arg2)
    return unless data

    scope = HelperFunctions.scope_for(data)
    scoped_data = case scope.arity
                  when 0 then scope.call
                  when 1 then scope.call(data)
                  when 2 then scope.call(data, actor)
                  end

    scoped_data || data
  end
end
