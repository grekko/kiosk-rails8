class Api::MonthlyReportsController < Api::BaseController
  before_action :set_monthly_report, only: %i[ complete reopen ]

  def index
    monthly_reports = MonthlyReport.order(id: :desc)
    monthly_reports = monthly_reports.by_state(params[:state]) if params[:state].present?

    render json: {
      monthly_reports: monthly_reports.map { |report| Api::MonthlyReportSerializer.call(report) }
    }
  end

  def complete
    @monthly_report.complete!

    render_monthly_report
  end

  def reopen
    @monthly_report.reopen!

    render_monthly_report
  end

  private

  def set_monthly_report
    @monthly_report = MonthlyReport.find(params.expect(:id))
  end

  def render_monthly_report
    render json: { monthly_report: Api::MonthlyReportSerializer.call(@monthly_report) }
  end
end
