class AddSuspendedAtToClients < ActiveRecord::Migration[8.0]
  def change
    add_column :clients, :suspended_at, :datetime
  end
end
