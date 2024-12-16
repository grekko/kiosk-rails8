class Client < ApplicationRecord
  has_many :settlements

  validates :name, presence: true
end
