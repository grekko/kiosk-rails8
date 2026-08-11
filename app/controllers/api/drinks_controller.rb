class Api::DrinksController < Api::BaseController
  def index
    drinks = Drink.includes(:settlement_prices).order(:name)

    render json: { drinks: drinks.map { |drink| Api::DrinkSerializer.call(drink) } }
  end
end
