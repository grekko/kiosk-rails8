class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.belongs_to(:client, foreign_key: true, null: false)
      t.integer :amount_in_cents, null: false, default: 0

      t.string :aasm_state, null: false, default: "draft"
      t.datetime :settled_at

      t.text :note

      t.timestamps
    end

    add_reference :settlements, :payment, foreign_key: true
  end
end
