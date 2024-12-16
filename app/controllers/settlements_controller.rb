class SettlementsController < ApplicationController
  before_action :set_settlement, only: %i[ edit update destroy complete mark_paid ]

  def index
    @settlements = Settlement.order(generated_at: :desc).all
  end

  def filtered
    @client = Client.find(params[:client_id])
    @settlements = Settlement.where(client: @client).order(generated_at: :desc).all
  end

  def new
    @settlement = Settlement.new(generated_at: Time.current)
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

  def complete
    @settlement.complete!
    redirect_to settlements_path
  end

  def mark_paid
    @settlement.mark_paid!
    redirect_to settlements_path
  end

  def destroy
    if @settlement.draft?
      @settlement.destroy!
    end

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
