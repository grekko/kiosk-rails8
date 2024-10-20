class OrderPositionsController < ApplicationController
  before_action :set_order
  before_action :set_order_position, only: %i[ edit update ]

  def create
    @order_position = OrderPosition.create(create_order_params)
    redirect_to edit_order_path(@order)
  end

  def edit
  end

  def update
    if @order_position.update(order_position_params)
      redirect_to edit_order_path(@order)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    order_position = @order.positions.find(params[:id])
    order_position.destroy!
    redirect_to edit_order_path(@order)
  end

  private

  def set_order
    @order = Order.find(params[:order_id])
  end

  def set_order_position
    @order = OrderPosition.find(params[:id])
  end

  def create_order_params
    order_position_params.merge(order: @order)
  end

  def order_position_params
    params.expect(order_position: [ :drink_id, :amount, :price_in_cents, :deposit_in_cents ])
  end
end
