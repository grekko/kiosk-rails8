class Order < ApplicationRecord
  validates :ordered_at, presence: true
end
