class CreateDrinks < ActiveRecord::Migration[8.0]
  def change
    create_table :drinks do |t|
      t.string :name, null: false
      t.integer :price_in_cents, null: false, default: 0

      t.timestamps
    end
  end
end
