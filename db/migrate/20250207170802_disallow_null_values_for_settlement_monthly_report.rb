class DisallowNullValuesForSettlementMonthlyReport < ActiveRecord::Migration[8.0]
  def change
    change_column_null :settlements, :monthly_report_id, false
  end
end
