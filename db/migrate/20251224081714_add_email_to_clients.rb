class AddEmailToClients < ActiveRecord::Migration[8.0]
  def change
    add_column :clients, :email, :text
    add_index :clients, :email, unique: true
  end
end
