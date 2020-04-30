class CreateAllTables < ActiveRecord::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[5.0] : ActiveRecord::Migration
  def self.up
    create_table(:users) {|t| t.string :role; t.references :friend }
    create_table(:transactions) {|t| t.boolean :is_settled; t.references :user }

  end
end

CreateAllTables.up
