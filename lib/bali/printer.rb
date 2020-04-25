require "stringio"
require "date"

# module that would allow all defined rules to be printed for check
module Bali::Printer
  module_function

  SEPARATOR = " " * 6
  SUBTARGET_TITLE_SEPARATOR = SEPARATOR + ("-" * 80) + "\n"

  def pretty_print
    output = StringIO.new

    # build up the string for pretty printing rules
    Bali::RULE_CLASS_MAP.each do |klass, rule_class|
      output << "===== #{klass.to_s} =====\n\n"

      rule_class.rule_groups.each do |subtarget, rule_group|
        print_rule_group(rule_group, output)
      end

      if rule_class.others_rule_group.rules.any?
        print_rule_group(rule_class.others_rule_group, output)
      end
      output << "\n\n"
    end

    output << "\n\n"
    output << DateTime.now.strftime("Printed at %d-%m-%Y %I:%M%p %Z")

    output.string
  end

  def print_rule_group(rule_group, target_io)
    target = rule_group.target.to_s
    subtarget = rule_group.subtarget.to_s.capitalize
    subtarget = "Others" if subtarget == "__*__"
    can_all = rule_group.can_all?
    counter = 0

    target_io << "#{SEPARATOR}#{subtarget}, can all: #{can_all}, cant all: #{!can_all}\n"
    target_io << SUBTARGET_TITLE_SEPARATOR

    if can_all
      target_io << "#{SEPARATOR}  #{counter+=1}. #{subtarget} can do anything except if explicitly stated otherwise\n"
    end

    rule_group.rules.each do |rule|
      written_rule = StringIO.new
      written_rule << "#{SEPARATOR}  #{counter+=1}. #{subtarget} #{rule.auth_val} #{rule.operation} #{target}"
      if rule.has_decider?
        written_rule << ", with condition"
      end
      written_rule << "\n"
      target_io << written_rule.string
    end

    target_io << "\n"
  end
end
