class CreateMonthlyReports < ActiveRecord::Migration[8.0]
  def change
    create_table :monthly_reports do |t|
      t.text :title
      t.text :description
      t.timestamps
    end
  end
end
