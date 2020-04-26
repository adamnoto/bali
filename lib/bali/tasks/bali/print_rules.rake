namespace :bali do
  desc "Print all rules nicely"
  task print_rules: :environment do
    rules_path = Bali.config.rules_path
    Dir.glob("#{rules_path}/**/*.rb").each { |f| load f }

    $stdout.puts Bali::Printer.pretty_print
  end
end
