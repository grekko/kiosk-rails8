class RemoveStateMachineFieldsFromPayments < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL
      UPDATE settlements SET payment_id = NULL WHERE aasm_state != 'paid';
      DELETE FROM payments WHERE aasm_state != 'settled';
    SQL
    remove_column :payments, :aasm_state, :text
    remove_column :payments, :settled_at, :datetime
    remove_column :payments, :note, :text
  end
end
