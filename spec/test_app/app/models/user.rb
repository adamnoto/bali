class User < ActiveRecord::Base
  extract_roles_from :role

  belongs_to :friend, class_name: "User"
  has_many :friends, class_name: "User", foreign_key: :friend_id

  def self.no_more_beta?
    true
  end

  def role
    role = read_attribute :role

    if role && role.start_with?("[")
      JSON.parse role
    else
      role
    end
  end
end
