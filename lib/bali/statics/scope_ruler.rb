module Bali::Statics::ScopeRuler
  module HelperFunctions
    extend self
  end

  def rule_scope(arg1, arg2)
    if arg2.nil?
      data = arg1
      if respond_to?(:current_user)
        actor = arg1
      end
    else
      actor, data = arg1, arg2
    end
  end
end
