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

  def cant?(subtargets, operation)
    self.class.cant?(subtargets, operation, self)
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
  end

  def cant?(subtarget_roles, operation, record = self, options = {})
    subs = bali_translate_subtarget_roles subtarget_roles
    original_subtarget = options[:original_subtarget].nil? ? subtarget_roles : options[:original_subtarget]

    judgement_value = true
    role = nil
    judger = nil

    subs.each do |subtarget|
      next if judgement_value == false

      judge = Bali::Judger::Judge.build(:cant, {
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
  end
end
