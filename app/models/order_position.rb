class OrderPosition < ApplicationRecord
  belongs_to :order
  belongs_to :drink

  validates :amount, presence: true, numericality: true
  validates :price_in_cents, presence: true, numericality: true
  validates :deposit_in_cents, presence: true, numericality: true
end
