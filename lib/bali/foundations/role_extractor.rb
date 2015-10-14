class Bali::RoleExtractor
  attr_reader :arg
  
  # argument can be anything, as long as role extractor know how to extract
  def initialize(arg)
    @arg = arg
  end

  def get_roles(object = @arg)
    case object
    when String; get_role_string(object)
    when Symbol; get_role_symbol(object)
    when NilClass; get_role_nil(object)
    when Array; get_role_array(object)
    else
      get_role_object(object)
    end
  end

  private
    def get_role_string(object)
      [object]
    end

    def get_role_symbol(object)
      [object]
    end

    def get_role_nil(object)
      [object]
    end

    def get_role_array(object)
      object
    end

    # this case, _subtarget_roles is an object but not a symbol or a string
    # let's try to deduct subtarget's roles
    def get_role_object(object)
      object_class = object.class.to_s

      # variable to hold deducted role of the passed object
      deducted_roles = nil
      role_extracted = false

      Bali::TRANSLATED_SUBTARGET_ROLES.each do |current_subtarget_class, roles_field_name|
        if object_class == current_subtarget_class
          deducted_roles = object.send(roles_field_name)
          deducted_roles = get_role(deducted_roles)
          role_extracted = true
          break
        end # if matching class
      end # each TRANSLATED_SUBTARGET_ROLES

      unless role_extracted
        raise Bali::AuthorizationError, "Bali does not know how to process roles: #{object}"
      end

      deducted_roles
    end
end
