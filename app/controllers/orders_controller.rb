class OrdersController < ApplicationController
  before_action :set_order, only: %i[ edit update destroy ]

  def index
    @orders = Order.all
  end

  def new
    @order = Order.new(ordered_at: Time.current)
  end

  def edit
  end

  def create
    @order = Order.new(order_params)

    if @order.save
      redirect_to edit_order_path(@order)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @order.update(order_params)
      redirect_to orders_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @order.destroy!
    redirect_to orders_path
  end

  private

  def set_order
    @order = Order.includes(positions: [ :drink ]).find(params.expect(:id))
  end

  def order_params
    params.expect(order: [ :ordered_at ])
  end
end
