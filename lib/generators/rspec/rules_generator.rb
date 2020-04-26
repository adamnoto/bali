module Rspec
  module Generators
    class RulesGenerator < ::Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      def create_spec_file
        template "rules_spec.rb",
          File.join(Bali.config.rules_path, "#{file_name}_#{Bali.config.suffix.downcase}_spec.rb")
      end
    end
  end
end
