class Api::SettlementsController < Api::BaseController
  before_action :set_settlement, only: %i[ show update complete send_email ]

  def index
    settlements = Settlement.includes(:client, :monthly_report, positions: :drink).newest_first
    settlements = settlements.where(client_id: params[:client_id]) if params[:client_id].present?
    settlements = settlements.where(monthly_report_id: params[:monthly_report_id]) if params[:monthly_report_id].present?
    settlements = settlements.where(aasm_state: params[:state]) if params[:state].present?

    render json: { settlements: settlements.map { |settlement| Api::SettlementSerializer.call(settlement) } }
  end

  def show
    render_settlement
  end

  def create
    attributes = create_params
    positions = attributes.delete(:positions) || []
    @settlement = Settlement.new(attributes)

    Settlement.transaction do
      @settlement.save!
      positions.each { |position| @settlement.positions.create!(position) }
    end

    @settlement.positions.reload
    render_settlement(status: :created)
  end

  def update
    @settlement.update!(update_params)

    render_settlement
  end

  def complete
    @settlement.complete!

    render_settlement
  end

  def send_email
    return render_validation_errors(@settlement) unless @settlement.schedule_email_delivery

    render_settlement
  end

  private

  def set_settlement
    @settlement = Settlement.includes(:client, :monthly_report, positions: :drink).find(params.expect(:id))
  end

  def render_settlement(status: :ok)
    render json: { settlement: Api::SettlementSerializer.call(@settlement) }, status: status
  end

  def create_params
    params.expect(
      settlement: [ :client_id, :monthly_report_id, :generated_at, :paid_at, positions: [ [ :drink_id, :amount ] ] ]
    )
  end

  def update_params
    params.expect(settlement: [ :client_id, :monthly_report_id, :generated_at, :paid_at ])
  end
end
