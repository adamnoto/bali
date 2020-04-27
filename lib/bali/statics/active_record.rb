module Bali::Statics::ActiveRecord
  def self.extended(cls)
    cls.class_eval do
      cattr_accessor :role_field_for_authorization

      def self.extract_roles_from method_name
        self.role_field_for_authorization = method_name
      end
    end
  end
end
