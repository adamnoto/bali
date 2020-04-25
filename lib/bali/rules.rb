class Bali::Rules
  def self.can(*args)
    add_can(current_rule_group, *args)
  end

  def self.cant(*args)
    add_cant(current_rule_group, *args)
  end

  def self.cant_all(*args)
    current_rule_group.can_all = false
  end

  def self.can_all(*args)
    current_rule_group.can_all = true
  end

  def self.role(*params)
    bali_scrap_actors(*params).each do |subtarget|
      bali_set_subtarget(subtarget)

      if block_given?
        yield
      else
        # if no block, then rules are defined using shortcut notation, eg:
        # role :user, can: [:edit]
        # the last element of which params must be a hash
        shortcut_rules = params[-1]
        unless shortcut_rules.is_a?(Hash)
          raise Bali::DslError, "Pass a hash for shortcut notation"
        end
      end # whether block is given or not
    end # each subtarget
  end

  def self.current_rule_group
    @@current_rule_group ||= bali_set_subtarget("__*__")
  end

  private

    def self.model_class
      class_name = to_s
      class_name[0...class_name.length - Bali.config.suffix.length].constantize
    end

    def self.current_rule_class
      @@current_rule_class ||= begin
        rule_class = Bali::RuleClass.new(model_class)
        Bali::Integrator::RuleClass.add(rule_class)
        rule_class
      end
    end

    def self.bali_scrap_actors(*params)
      current_subtargets = []
      params.each do |param|
        if Symbol === param || String === param || NilClass
          current_subtargets << param
        else
          raise Bali::DslError, "Cannot define role using #{param.class}. Please use either a Symbol, a String or nil"
        end
      end
      current_subtargets
    end

    # set the current processing on a specific subtarget
    def self.bali_set_subtarget(subtarget)
      rule_group = current_rule_class.rules_for(subtarget)

      if rule_group.nil?
        rule_group = Bali::RuleGroup.new(model_class, subtarget)
      end

      current_rule_class.add_rule_group rule_group
      @@current_rule_group = rule_group
    end

    # to define can and cant is basically using this method
    # args can comprises of symbols, and hash (for condition)
    def self.add(auth_val, rule_group, *args)
      conditional_hash = nil
      operations = []

      # scan args for options
      args.each do |elm|
        if elm.is_a?(Hash)
          conditional_hash = elm
        else
          operations << elm
        end
      end

      # add operation one by one
      operations.each do |op|
        rule = Bali::Rule.new(auth_val, op)
        embed_condition(rule, conditional_hash)

        if rule_group.nil?
          bali_set_subtarget("__*__")
          rule_group = current_rule_group
        end

        rule_group.add_rule(rule)
      end
    end # bali_process_auth_rules

    # add can rule programatically
    def self.add_can(rule_group, *args)
      add :can, rule_group, *args
    end

    # add cant rule programatically
    def self.add_cant(rule_group, *args)
      add :cant, rule_group, *args
    end

    # process conditional statement in rule definition
    # conditional hash: {if: proc} or {unless: proc}
    def self.embed_condition(rule, conditional_hash = nil)
      return if conditional_hash.nil?

      condition_type = conditional_hash.keys[0].to_s.downcase
      condition_type_symb = condition_type.to_sym

      if condition_type_symb == :if
        rule.decider = conditional_hash.values[0]
      end
      nil
    end

end
