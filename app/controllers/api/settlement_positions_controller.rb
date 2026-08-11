class Api::SettlementPositionsController < Api::BaseController
  before_action :set_settlement
  before_action :set_position, only: %i[ update destroy ]

  def create
    @position = @settlement.positions.create!(position_params)

    render_position(status: :created)
  end

  def update
    @position.update!(position_params)

    render_position
  end

  def destroy
    @position.destroy!

    head :no_content
  end

  private

  def set_settlement
    @settlement = Settlement.find(params.expect(:settlement_id))
  end

  def set_position
    @position = @settlement.positions.find(params.expect(:id))
  end

  def render_position(status: :ok)
    render json: { position: Api::SettlementPositionSerializer.call(@position) }, status: status
  end

  def position_params
    params.expect(position: [ :drink_id, :amount ])
  end
end
