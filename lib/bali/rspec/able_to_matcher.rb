module RSpec
  module Matchers
    module BuiltIn
      class AbleToMatcher < Be
        def initialize(operation, class_or_record = nil)
          @operation = operation
          @class_or_record = class_or_record
        end

        def matches?(actor)
          if @class_or_record
            rule_class = "#{@class_or_record.class.name}#{Bali.config.suffix}".constantize
            rule_class.can?(actor, @operation, @class_or_record)
          else
            @class_or_record = actor
            rule_class = "#{@class_or_record.name}#{Bali.config.suffix}".constantize
            rule_class.can?(nil, @operation, @class_or_record)
          end
        end

        def failure_message
          "expected to be able to #{@operation}, but actually cannot"
        end

        def failure_message_when_negated
          "expected not to be able to #{@operation}, but actually can"
        end

        def description
          "be able to #{@operation}"
        end
      end
    end

    def be_able_to(*args)
      BuiltIn::AbleToMatcher.new(*args)
    end
  end
end
