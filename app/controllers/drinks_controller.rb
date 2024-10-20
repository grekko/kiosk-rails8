class DrinksController < ApplicationController
  before_action :set_drink, only: %i[ edit update destroy ]

  def index
    @drinks = Drink.all
  end

  def new
    @drink = Drink.new
  end

  def edit
  end

  def create
    @drink = Drink.new(drink_params)

    if @drink.save
      redirect_to drinks_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @drink.update(drink_params)
      redirect_to drinks_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @drink.destroy!
    redirect_to drinks_path
  end

  private

  def set_drink
    @drink = Drink.find(params.expect(:id))
  end

  def drink_params
    params.expect(drink: [ :name, :price_in_cents ])
  end
end
