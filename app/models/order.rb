class Order < ApplicationRecord
  validates :ordered_at, presence: true

  has_many :positions, class_name: "OrderPosition", dependent: :destroy

  def price_in_cents
    positions.sum(:price_in_cents)
  end

  def deposit_in_cents
    positions.sum(:deposit_in_cents)
  end

  def total_price_in_cents
    positions.sum(:total_price_in_cents)
  end
end
