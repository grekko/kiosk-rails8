class MonthlyReportsController < ApplicationController
  before_action :set_monthly_report, only: %i[ edit update complete reopen complete_settlements schedule_settlement_emails ]

  def index
    @state = params[:state].presence
    @monthly_reports = MonthlyReport.order(id: :desc)
    @monthly_reports = @monthly_reports.by_state(@state) if @state
  end

  def new
    @monthly_report = MonthlyReport.new
  end

  def edit
    @settlements = @monthly_report.settlements.includes(:client)
    settled_clients = @settlements.map(&:client)
    @clients = Client.active - settled_clients
  end

  def create
    @monthly_report = MonthlyReport.new(monthly_report_params)

    if @monthly_report.save
      redirect_to monthly_reports_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @monthly_report.update(monthly_report_params)
      redirect_to monthly_reports_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def complete
    @monthly_report.complete!

    redirect_back fallback_location: monthly_reports_path, notice: "Report marked as completed."
  end

  def reopen
    @monthly_report.reopen!

    redirect_back fallback_location: monthly_reports_path, notice: "Report moved back to draft."
  end

  def complete_settlements
    @monthly_report.complete_settlements!

    redirect_back fallback_location: edit_monthly_report_path(@monthly_report)
  end

  def schedule_settlement_emails
    scheduled_count = @monthly_report.schedule_settlement_emails!

    if scheduled_count.positive?
      redirect_back fallback_location: settlements_path,
                    notice: "#{helpers.pluralize(scheduled_count, 'email')} scheduled."
    else
      redirect_back fallback_location: settlements_path, alert: "No emails were scheduled."
    end
  end

  private

  def set_monthly_report
    @monthly_report = MonthlyReport.find(params.expect(:id))
  end

  def monthly_report_params
    params.expect(monthly_report: [ :title, :description, :image ])
  end
end
