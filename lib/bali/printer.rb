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

      rule_class.roles.each do |subtarget, role|
        print_role role, output
      end

      output << "\n\n"
    end

    output << "\n\n"
    output << DateTime.now.strftime("Printed at %d-%m-%Y %I:%M%p %Z")

    output.string
  end

  def print_role role, target_io
    subtarget = role.subtarget.to_s.capitalize
    subtarget = "By default" if subtarget.blank?
    can_all = role.can_all?
    counter = 0

    target_io << "#{SEPARATOR}#{subtarget}\n"
    target_io << SUBTARGET_TITLE_SEPARATOR

    if can_all
      target_io << "#{SEPARATOR}  #{counter+=1}. #{subtarget} can do anything except if explicitly stated otherwise\n"
    end

    role.rules.each do |rule|
      written_rule = StringIO.new
      written_rule << "#{SEPARATOR}  #{counter+=1}. #{subtarget} #{rule.term} #{rule.operation}"
      if rule.conditional?
        written_rule << ", with condition"
      end
      written_rule << "\n"
      target_io << written_rule.string
    end

    target_io << "\n"
  end
end
