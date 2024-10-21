class AddStateAndCompletdAtToSettlements < ActiveRecord::Migration[8.0]
  def change
    change_table :settlements do |t|
      t.string :aasm_state, null: false, default: "draft"
      t.datetime :completed_at
    end
  end
end
