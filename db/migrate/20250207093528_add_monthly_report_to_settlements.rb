class AddMonthlyReportToSettlements < ActiveRecord::Migration[8.0]
  def change
    add_reference :settlements, :monthly_report, foreign_key: true
  end
end
