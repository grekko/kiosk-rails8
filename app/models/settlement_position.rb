class SettlementPosition < ApplicationRecord
  belongs_to :settlement
  belongs_to :drink

  validates :amount, presence: true, numericality: true
  validates :price_in_cents, presence: true, numericality: true

  before_validation :set_price_in_cents, on: :create

  private

  def set_price_in_cents
    return if drink.blank? || amount.blank?

    self.price_in_cents = amount * drink.price_in_cents
  end
end
