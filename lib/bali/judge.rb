class Bali::Judge
  # Fuzy value is possible when the evaluation is not yet clear cut, for example in this case:
  #
  # role :finance do
  #   cant :view
  # end
  #
  # others do
  #   can :view
  #   can :index
  # end
  #
  # Checking cant view for finance role results in a definite false, but
  # checking on index for the same role results in FUZY_TRUE. Eventually, all FUZY value will be
  # normal TRUE or FALSE if no definite counterpart is found.

  FUZY_FALSE = -2
  FUZY_TRUE = 2
  DEFINITE_FALSE = -1
  DEFINITE_TRUE = 1

  attr_accessor :term,
    :actor,
    :role,
    :operation,
    :record,
    :should_cross_check

  class << self
    def default_judgement_value(term)
      case term
      when :can then false
      when :cant then true
      end
    end

    def check(term, actor_or_roles, operation, record)
      if operation.nil?
        # eg: user.can? :sign_in
        operation = actor_or_roles
        actor_or_roles = nil
      end

      judgement_value = default_value = default_judgement_value(term)
      roles = Bali::Role.formalize actor_or_roles

      roles.each do |role|
        judge = Bali::Judge.new(
          term: term,
          role: role,
          actor: actor_or_roles,
          operation: operation,
          record: record
        )

        judgement_value = judge.judgement
        break if judgement_value != default_value
      end

      judgement_value
    end
  end

  def initialize(term:,
    actor:,
    role:,
    operation:,
    record:,
    should_cross_check: true)

    @term = term
    @role = role
    @actor = actor
    @operation = operation
    @record = record
    @should_cross_check = should_cross_check
  end

  def judgement
    judgement = natural_value if no_rule_group?

    if judgement.nil? && rule.nil? && may_have_reservation?
      judgement = cross_check_reverse_value(cross_check_judge.judgement)
    end

    if judgement.nil? && rule.nil?
      cross_check_value = nil
      # default if can? for undefined rule is false, after related clause
      # cant be found in cant?
      cross_check_value = cross_check_judge.judgement if should_cross_check

      # if cross check value nil, then the reverse rule is not defined,
      # let's determine whether they can do anything or not
      if cross_check_value.nil?
        judgement = deduce_from_defined_disposition
      else
        # process value from cross checking
        if otherly_rule && (cross_check_value == FUZY_FALSE || cross_check_value == FUZY_TRUE)
          # give chance to check at others block
          @rule = otherly_rule
        else
          judgement = cross_check_reverse_value(cross_check_value)
        end
      end
    end

    judgement ||= deduce_by_evaluation ||
      deduce_from_fuzy_rules ||
      natural_value

    return !should_cross_check ?
      judgement :

      # translate response for value above to traditional true/false
      # holy judgement refer to non-standard true/false being used inside Bali
      # which need to be translated from other beings to know
      judgement > 0
  end

  private

    def record_class
      record.is_a?(Class) ? record : record.class
    end

    def ruler
      @ruler ||= Bali::Ruler.for record_class
    end

    def rule_group_for(role)
      ruler.nil? ? nil : ruler[role]
    end

    def rule_group
      @rule_group ||= rule_group_for role
    end

    def other_rule_group
      @other_rule_group ||= rule_group_for nil
    end

    def no_rule_group?
      rule_group.nil? && other_rule_group.nil?
    end

    def rule
      # rule group may be nil, for when user checking for undefined rule group
      @rule ||= rule_group ? rule_group.find_rule(term, operation) : nil
    end

    def otherly_rule
      @otherly_rule ||= other_rule_group ? other_rule_group.find_rule(term, operation) : nil
    end

    def cross_check_judge
      @cross_check_judge ||= begin
        Bali::Judge.new(
          term: reversed_term,
          role: role,
          operation: operation,
          record: record,
          should_cross_check: false,
          actor: actor
        )
      end
    end

    def reversed_term
      case term
      when :can then :cant
      when :cant then :can
      end
    end

    def natural_value
      term == :cant ? DEFINITE_TRUE : DEFINITE_FALSE
    end

    # returns true if we need to check rule that can overwrite
    # the most powerful rule defined
    def may_have_reservation?
      term == :cant ?
        (rule_group && rule_group.cant_all?) :
        (rule_group && rule_group.can_all?)
    end

    def evaluate(rule, actor, record)
      conditional = rule.conditional
      evaluation  = case conditional.arity
                    when 0 then conditional.()
                    when 1 then conditional.(record)
                    when 2 then conditional.(record, actor)
                    end

      evaluation ? DEFINITE_TRUE : DEFINITE_FALSE
    end

    def cross_check_reverse_value(cross_check_value)
      case cross_check_value
      when DEFINITE_TRUE then DEFINITE_FALSE
      when DEFINITE_FALSE then DEFINITE_TRUE
      when FUZY_FALSE then FUZY_TRUE
      when FUZY_TRUE then FUZY_FALSE
      end
    end

    def deduce_by_evaluation
      return unless rule

      rule.conditional? ?
        evaluate(rule, actor, record) :
        judgement = DEFINITE_TRUE
    end

    def deduce_from_defined_disposition
      return unless rule_group

      if rule_group.can_all?
        term == :cant ? DEFINITE_FALSE : DEFINITE_TRUE
      elsif rule_group.cant_all?
        term == :cant ? DEFINITE_TRUE : DEFINITE_FALSE
      end
    end

    def deduce_from_fuzy_rules
      reversed_otherly_rule = other_rule_group.find_rule(reversed_term, operation)

      if reversed_otherly_rule
        term == :cant ? FUZY_TRUE : FUZY_FALSE
      end
    end

end
