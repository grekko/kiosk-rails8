class Drink < ApplicationRecord
  validates :name, presence: true
  validates :price_in_cents, presence: true, numericality: true
end
