class Bali::Config
  attr_accessor :rules_path
  attr_accessor :suffix

  def initialize
    if Rails.respond_to?(:root) && Rails.root
      @rules_path = Rails.root.join("app", "rules")
    end

    @suffix = "Rules"
  end
end
