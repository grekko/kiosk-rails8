class Api::MonthlyReportSerializer
  def self.call(monthly_report)
    {
      id: monthly_report.id,
      title: monthly_report.title,
      description: monthly_report.description,
      created_at: monthly_report.created_at&.iso8601
    }
  end
end
