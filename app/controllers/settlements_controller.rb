class SettlementsController < ApplicationController
  before_action :set_settlement, only: %i[ edit update destroy ]

  def index
    @settlements = Settlement.all
  end

  def new
    @settlement = Settlement.new
  end

  def edit
  end

  def create
    @settlement = Settlement.new(settlement_params)

    if @settlement.save
      redirect_to edit_settlement_path(@settlement)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @settlement.update(settlement_params)
      redirect_to edit_settlement_path(@settlement)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @settlement.destroy!
    redirect_to settlements_path
  end

  private

  def set_settlement
    @settlement = Settlement.find(params.expect(:id))
  end

  def settlement_params
    params.expect(settlement: [ :client_id, :generated_at, :paid_at ])
  end
end
