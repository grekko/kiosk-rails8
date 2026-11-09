class SettlementPositionsController < ApplicationController
  before_action :set_settlement
  before_action :set_position, only: %i[ edit update ]

  def create
    @position = SettlementPosition.new(create_position_params)
    if @position.save
      redirect_to edit_settlement_path(@settlement)
    else
      render_refused "settlements/edit"
    end
  end

  def edit
  end

  def update
    if @position.update(position_params)
      redirect_to edit_settlement_path(@settlement)
    else
      render_refused :edit
    end
  end

  def destroy
    position = @settlement.positions.find(params[:id])
    if position.destroy
      redirect_to edit_settlement_path(@settlement)
    else
      @position = position
      render_refused "settlements/edit"
    end
  end

  private

  # The position form is hidden or disabled on a completed Settlement, so its
  # inline errors may not show; the flash carries the message instead.
  def render_refused(template)
    flash.now[:alert] = @position.errors.full_messages.to_sentence
    render template, status: :unprocessable_entity
  end

  def set_settlement
    @settlement = Settlement.find(params[:settlement_id])
  end

  def set_position
    @position = @settlement.positions.find(params[:id])
  end

  def create_position_params
    position_params.merge(settlement: @settlement)
  end

  def position_params
    params.expect(settlement_position: [ :drink_id, :amount ])
  end
end
