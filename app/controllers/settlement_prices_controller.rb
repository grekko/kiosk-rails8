class SettlementPricesController < ApplicationController
  before_action :set_price, only: %i[ edit update deactivate ]

  def index
    @prices = SettlementPrice.active
  end

  def new
    @price = SettlementPrice.new(valid_from: Time.current)
  end

  def edit
  end

  def create
    @price = SettlementPrice.new(price_params)

    if @price.save
      redirect_to settlement_prices_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @price.update(price_params)
      redirect_to settlement_prices_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def deactivate
    @price.deactivate
    redirect_to settlement_prices_path
  end

  private

  def set_price
    @price = SettlementPrice.find(params.expect(:id))
  end

  def price_params
    params.expect(settlement_price: [ :drink_id, :price_in_cents, :valid_from ])
  end
end
