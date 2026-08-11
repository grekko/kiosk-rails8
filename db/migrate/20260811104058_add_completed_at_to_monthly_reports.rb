class AddCompletedAtToMonthlyReports < ActiveRecord::Migration[8.0]
  def change
    add_column :monthly_reports, :completed_at, :datetime
  end
end
