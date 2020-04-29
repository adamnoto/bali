module Bali::Statics::Authorizer
  module HelperFunctions
    extend self

    def find_actor(actor, operation, record = nil)
      Symbol === actor || String === actor ?
        nil :
        actor
    end

    def find_operation(actor, operation, record = nil)
      Symbol === actor || String === actor ?
        actor :
        operation
    end

    def find_record(actor, operation, record = nil)
      if (Symbol === actor || String === actor) && record.nil?
        operation
      elsif actor.is_a?(ActiveRecord::Base) && record.nil?
        actor.class
      else
        record
      end
    end

    def check(term, arg1, arg2, arg3)
      actor = HelperFunctions.find_actor(arg1, arg2, arg3)
      operation = HelperFunctions.find_operation(arg1, arg2, arg3)
      record = HelperFunctions.find_record(arg1, arg2, arg3)

      Bali::Judge.check(term, actor, operation, record)
    end
  end

  def can?(arg1, arg2 = nil, arg3 = nil)
    arg3 = model_class if (arg2.nil? || arg1.nil?) && arg3.nil?

    HelperFunctions.check(:can, arg1, arg2, arg3)
  end

  def cant?(arg1, arg2 = nil, arg3 = nil)
    arg3 = model_class if (arg2.nil? || arg1.nil?) && arg3.nil?

    HelperFunctions.check(:cant, arg1, arg2, arg3)
  end
end
