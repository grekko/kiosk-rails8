class Api::MonthlyReportSerializer
  def self.call(monthly_report)
    {
      id: monthly_report.id,
      title: monthly_report.title,
      description: monthly_report.description,
      state: monthly_report.state,
      completed_at: monthly_report.completed_at&.iso8601,
      created_at: monthly_report.created_at&.iso8601
    }
  end
end
