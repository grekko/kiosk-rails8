class Api::MonthlyReportsController < Api::BaseController
  def index
    monthly_reports = MonthlyReport.order(id: :desc)

    render json: {
      monthly_reports: monthly_reports.map { |report| Api::MonthlyReportSerializer.call(report) }
    }
  end
end
