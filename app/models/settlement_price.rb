class SettlementPrice < ApplicationRecord
  belongs_to :drink

  validates :valid_from, presence: true
  validates :price_in_cents, presence: true, numericality: true

  scope :active, -> { where(deactivated_at: nil) }

  def deactivate
    update(deactivated_at: Time.current)
  end
end
