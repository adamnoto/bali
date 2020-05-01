module Bali::Statics::ScopeRuler
  def rule_scope(arg1, arg2 = nil)
    if arg2.nil?
      data = arg1
      if respond_to?(:current_user)
        actor = current_user
      end
    else
      data, actor = arg1, arg2
    end

    return unless data

    rule_class = Bali::Rules.for(data.model)
    return unless rule_class
    scope = rule_class.inheritable_role.scope

    if scope.arity == 0
      scoped_data = scope.call
    elsif scope.arity == 1
      scoped_data = scope.call(data)
    elsif scope.arity == 2
      scoped_data = scope.call(data, actor)
    end

    scoped_data || data
  end
end
