module Bali::Statics::Record
  def self.extended(cls)
    cls.class_eval do
      class << self
        attr_accessor :role_field_for_authorization
      end

      def self.extract_roles_from method_name
        @role_field_for_authorization = method_name
      end
    end
  end
end
