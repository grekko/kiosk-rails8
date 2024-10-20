class Settlement < ApplicationRecord
  belongs_to :client
  has_many :positions, class_name: "SettlementPosition", dependent: :destroy

  validates :generated_at, presence: true

  def price_in_cents
    positions.sum(:price_in_cents)
  end
end
