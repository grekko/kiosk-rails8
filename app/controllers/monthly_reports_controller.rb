class MonthlyReportsController < ApplicationController
  before_action :set_monthly_report, only: %i[ edit update complete_settlements ]

  def index
    @monthly_reports = MonthlyReport.order(id: :desc).all
  end

  def new
    @monthly_report = MonthlyReport.new
  end

  def edit
    @settlements = @monthly_report.settlements.includes(:client)
    settled_clients = @settlements.map(&:client)
    @clients = Client.all - settled_clients
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

  def complete_settlements
    @monthly_report.complete_settlements!

    redirect_back fallback_location: edit_monthly_report_path(@monthly_report)
  end

  private

  def set_monthly_report
    @monthly_report = MonthlyReport.find(params.expect(:id))
  end

  def monthly_report_params
    params.expect(monthly_report: [ :title, :description, :image ])
  end
end
