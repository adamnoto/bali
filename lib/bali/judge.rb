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
    def check(term, actor_or_roles, operation, record)
      if operation.nil?
        # eg: user.can? :sign_in
        operation = actor_or_roles
        actor_or_roles = nil
      end

      judgement_value = default_value = term == :can ? false : true
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
    our_holy_judgement = natural_value if no_rule_group?

    if our_holy_judgement.nil? && rule.nil? && may_have_reservation?
      our_holy_judgement = cross_check_reverse_value(cross_check_judge.judgement)
    end

    if our_holy_judgement.nil? && rule.nil?
      cross_check_value = nil
      # default if can? for undefined rule is false, after related clause
      # cant be found in cant?
      if should_cross_check
        cross_check_value = cross_check_judge.judgement
      end

      # if cross check value nil, then the reverse rule is not defined,
      # let's determine whether they can do anything or not
      if cross_check_value.nil?
        # rule_group can be nil for when user checking under undefined rule-group
        if rule_group
          if rule_group.can_all?
            our_holy_judgement = term == :cant ? DEFINITE_FALSE : DEFINITE_TRUE
          elsif rule_group.cant_all?
            our_holy_judgement = term == :cant ? DEFINITE_TRUE : DEFINITE_FALSE
          end

        end # if rule_group exist
      else
        # process value from cross checking

        if otherly_rule && (cross_check_value == FUZY_FALSE || cross_check_value == FUZY_TRUE)
          # give chance to check at others block
          @rule = otherly_rule
        else
          our_holy_judgement = cross_check_reverse_value(cross_check_value)
        end
      end
    end # if our judgement nil and rule is nil

    # if our holy judgement is still nil, but rule is defined
    if our_holy_judgement.nil? && rule
      if rule.conditional?
        our_holy_judgement = run_condition(rule, actor, record)
      else
        our_holy_judgement = DEFINITE_TRUE
      end
    end

    # return fuzy if otherly rule defines contrary to this term
    if our_holy_judgement.nil? && rule.nil? && (other_rule_group && other_rule_group.find_rule(reversed_term, operation))
      if rule_group && (rule_group.can_all? || rule_group.cant_all?)
        # don't overwrite our holy judgement with fuzy value if rule group
        # zeus/plant, because zeus/plant is more definite than any fuzy values
        # eventhough the rule is abstractly defined
      else
        our_holy_judgement = term == :cant ? FUZY_TRUE : FUZY_FALSE
      end
    end

    # if at this point still nil, well,
    # return the natural value for this judge
    if our_holy_judgement.nil?
      if otherly_rule
        our_holy_judgement = FUZY_TRUE
      else
        our_holy_judgement = natural_value
      end
    end

    return !should_cross_check ?
      our_holy_judgement :

      # translate response for value above to traditional true/false
      # holy judgement refer to non-standard true/false being used inside Bali
      # which need to be translated from other beings to know
      our_holy_judgement > 0
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

    def run_condition(rule, actor, record)
      # must test first
      conditional = rule.conditional
      case conditional.arity
      when 0
        return conditional.() ? DEFINITE_TRUE : DEFINITE_FALSE
      when 1
        return conditional.(record) ? DEFINITE_TRUE : DEFINITE_FALSE
      when 2
        return conditional.(record, actor) ? DEFINITE_TRUE : DEFINITE_FALSE
      end
    end

    def cross_check_reverse_value(cross_check_value)
      case cross_check_value
      when DEFINITE_TRUE then DEFINITE_FALSE
      when DEFINITE_FALSE then DEFINITE_TRUE
      when FUZY_FALSE then FUZY_TRUE
      when FUZY_TRUE then FUZY_FALSE
      end
    end

end
