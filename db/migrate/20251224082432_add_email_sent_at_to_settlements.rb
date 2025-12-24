class AddEmailSentAtToSettlements < ActiveRecord::Migration[8.0]
  def change
    add_column :settlements, :email_sent_at, :datetime
  end
end
