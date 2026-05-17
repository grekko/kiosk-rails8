class AddEmailFirstOpenedAtToSettlements < ActiveRecord::Migration[8.0]
  def change
    add_column :settlements, :email_first_opened_at, :datetime
  end
end
