# module that will be included in each instantiated target classes as defined
# in map_rules
module Bali::Objector
  def self.included(base)
    base.extend Bali::Objector::Statics
  end

  # check whether user can/cant perform an operation, return true when positive
  # or false otherwise
  def can?(subtargets, operation)
    self.class.can?(subtargets, operation, self)
  end

  # check whether user can/cant perform an operation, raise an error when access
  # is denied
  def can!(subtargets, operation)
    self.class.can!(subtargets, operation, self)
  end

  # check whether user can/cant perform an operation, return true when negative
  # or false otherwise
  def cannot?(subtargets, operation)
    self.class.cannot?(subtargets, operation, self)
  end

  # check whether user can/cant perform an operation, raise an error when access
  # is given
  def cannot!(subtargets, operation)
    self.class.cannot!(subtargets, operation, self)
  end

  def cant?(subtargets, operation)
    puts "Deprecation Warning: please use cannot? instead, cant? will be deprecated on major release 3.0"
    cannot?(subtargets, operation)
  end

  def cant!(subtargets, operation)
    puts "Deprecation Warning: please use cannot! instead, cant! will be deprecated on major release 3.0"
    cannot!(subtargets, operation)
  end
end

# to allow class-level objection
module Bali::Objector::Statics
  # get the proper roles for the subtarget, for any type of subtarget
  def bali_translate_subtarget_roles(arg)
    role_extractor = Bali::RoleExtractor.new(arg)
    role_extractor.get_roles
  end

  def can?(subtarget_roles, operation, record = self, options = {})
    subs = bali_translate_subtarget_roles(subtarget_roles)
    # well, it is largely not used unless decider's is 2 arity
    original_subtarget = options[:original_subtarget].nil? ? subtarget_roles : options[:original_subtarget]

    judgement_value = false
    role = nil
    judger = nil

    subs.each do |subtarget|
      next if judgement_value == true

      judge = Bali::Judger::Judge.build(:can, {
        subtarget: subtarget,
        original_subtarget: original_subtarget,
        operation: operation,
        record: record
      })
      judgement_value = judge.judgement

      role = subtarget
    end

    if block_given?
      yield original_subtarget, role, judgement_value
    end

    judgement_value
  rescue => e
    if e.is_a?(Bali::AuthorizationError) || e.is_a?(Bali::Error)
      raise e
    else
      raise Bali::ObjectionError, e.message, e.backtrace
    end
  end

  def cannot?(subtarget_roles, operation, record = self, options = {})
    subs = bali_translate_subtarget_roles subtarget_roles
    original_subtarget = options[:original_subtarget].nil? ? subtarget_roles : options[:original_subtarget]

    judgement_value = true
    role = nil
    judger = nil

    subs.each do |subtarget|
      next if judgement_value == false

      judge = Bali::Judger::Judge.build(:cannot, {
        subtarget: subtarget,
        original_subtarget: original_subtarget,
        operation: operation,
        record: record
      })
      judgement_value = judge.judgement

      role = subtarget
    end

    if block_given?
      yield original_subtarget, role, judgement_value
    end

    judgement_value
  rescue => e
    if e.is_a?(Bali::AuthorizationError)
      raise e
    else
      raise Bali::ObjectionError, e.message, e.backtrace
    end
  end

  def can!(subtarget_roles, operation, record = self, options = {})
    can?(subtarget_roles, operation, record, options) do |original_subtarget, role, can_value|
      if !can_value
        auth_error = Bali::AuthorizationError.new
        auth_error.auth_level = :can
        auth_error.operation = operation
        auth_error.role = role
        auth_error.target = record
        auth_error.subtarget = original_subtarget

        if role
          auth_error.subtarget = original_subtarget if !(original_subtarget.is_a?(Symbol) || original_subtarget.is_a?(String) || original_subtarget.is_a?(Array))
        end

        raise auth_error
      else
        return can_value
      end # if cannot is false, means cannot
    end # can?
  end

  def cant!(subtarget_roles, operation, record = self, options = {})
    puts "Deprecation Warning: please use cannot! instead, cant! will be deprecated on major release 3.0"
    cannot!(subtarget_roles, operation, record, options)
  end

  def cant?(subtarget_roles, operation)
    puts "Deprecation Warning: please use cannot? instead, cant? will be deprecated on major release 3.0"
    cannot?(subtarget_roles, operation)
  end

  def cannot!(subtarget_roles, operation, record = self, options = {})
    cannot?(subtarget_roles, operation, record, options) do |original_subtarget, role, cant_value|
      if cant_value == false
        auth_error = Bali::AuthorizationError.new
        auth_error.auth_level = :cannot
        auth_error.operation = operation
        auth_error.role = role
        auth_error.target = record
        auth_error.subtarget = original_subtarget

        if role
          auth_error.subtarget = original_subtarget if !(original_subtarget.is_a?(Symbol) || original_subtarget.is_a?(String) || original_subtarget.is_a?(Array))
        end

        raise auth_error
      else
        return cant_value
      end # if cannot is false, means can
    end # cannot?
  end
end
