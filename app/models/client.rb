class Client < ApplicationRecord
  has_many :settlements
  has_many :payments

  validates :name, presence: true
end
