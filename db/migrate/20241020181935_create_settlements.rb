class CreateSettlements < ActiveRecord::Migration[8.0]
  def change
    create_table :settlements do |t|
      t.belongs_to(:client, foreign_key: true, null: false)
      t.datetime :paid_at

      t.timestamps
    end
  end
end
