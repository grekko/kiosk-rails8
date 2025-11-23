class OrdersController < ApplicationController
  before_action :set_order, only: %i[ edit update ]

  def index
    @orders = Order.order(ordered_at: :desc)
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

  private

  def set_order
    @order = Order.includes(:invoice_attachment, positions: [ :drink ]).find(params.expect(:id))
  end

  def order_params
    params.expect(order: [ :invoice, :ordered_at ])
  end
end
