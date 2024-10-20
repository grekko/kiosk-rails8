class Drink < ApplicationRecord
  validates :name, presence: true
  validates :price_in_cents, presence: true, numericality: true

  has_many :settlement_prices

  def price_in_cents_at(date:)
    settlement_price(date:)&.price_in_cents || price_in_cents
  end

  def settlement_price(date:)
    settlement_prices.order(valid_from: :desc).find_by(valid_from: Range.new(nil, date))
  end

  def current_price_in_cents = price_in_cents_at(date: Date.today)
  def current_settlement_price = settlement_price(date: Date.today)
end
