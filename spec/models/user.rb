class User
  include Bali::Authorizer
  extend Bali::Statics::ActiveRecord

  extract_roles_from :role

  attr_accessor :role
  attr_accessor :friends

  def initialize(role = nil)
    @role = role
    @friends = []
  end

  def self.no_more_beta?
    true
  end
end
