class AddAccessUuidToClients < ActiveRecord::Migration[8.0]
  def change
    add_column :clients, :access_uuid, :text
    add_index :clients, :access_uuid, unique: true

    reversible do |dir|
      dir.up do
        Client.find_each { |c| c.send(:set_access_uuid); c.save }
      end
    end
  end
end
