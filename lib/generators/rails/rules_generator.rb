# frozen_string_literal: true

module Rails
  module Generators
    class RulesGenerator < NamedBase
      source_root File.expand_path("templates", __dir__)
      check_class_collision suffix: Bali.config.suffix

      def create_decorator_file
        template "rules.rb",
          File.join(Bali.config.rules_path, "#{file_name}_#{Bali.config.suffix.downcase}.rb")
      end

      hook_for :test_framework
    end
  end
end
