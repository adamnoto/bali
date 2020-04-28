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
    rule_classes = ObjectSpace.each_object(Class).select { |cls| cls < Bali::Rules }
    rule_classes.sort! { |a, b| a.to_s <=> b.to_s }
    rule_classes.each do |rule_class|
      output << "===== #{rule_class.model_class} =====\n\n"

      rule_class.ruler.roles.each do |subtarget, role|
        print_role role, output
      end

      output << "\n\n"
    end

    output << DateTime.now.strftime("Printed at %Y-%m-%d %I:%M%p %Z")

    output.string
  end

  def print_role role, target_io
    subtarget = role.name.to_s.capitalize
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
  end
end
