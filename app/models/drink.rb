class Drink < ApplicationRecord
  validates :name, presence: true
  validates :price_in_cents, presence: true, numericality: true

  has_many :settlement_prices

  def price_in_cents_at(date:)
    settlement_prices.find_by(valid_from: Range.new(date, nil))&.price_in_cents
  end

  def current_price_in_cents = price_in_cents_at(date: Date.today)
end
