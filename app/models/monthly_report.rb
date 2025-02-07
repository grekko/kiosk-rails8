class MonthlyReport < ApplicationRecord
  has_many :settlements
  has_one_attached :image
end
