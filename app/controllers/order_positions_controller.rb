class OrderPositionsController < ApplicationController
  before_action :set_order
  before_action :set_position, only: %i[ edit update ]

  def create
    @position = OrderPosition.new(create_position_params)
    if @position.save
      redirect_to edit_order_path(@order)
    else
      render "orders/edit", status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @position.update(position_params)
      redirect_to edit_order_path(@order)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    position = @order.positions.find(params[:id])
    position.destroy!
    redirect_to edit_order_path(@order)
  end

  private

  def set_order
    @order = Order.find(params[:order_id])
  end

  def set_position
    @position = @order.positions.find(params[:id])
  end

  def create_position_params
    position_params.merge(order: @order)
  end

  def position_params
    params.expect(order_position: [ :drink_id, :amount, :price_in_cents, :deposit_in_cents ])
  end
end
