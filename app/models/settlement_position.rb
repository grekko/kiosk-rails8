class SettlementPosition < ApplicationRecord
  LOCKED_MESSAGE = "Settlement is completed, its positions can no longer be changed".freeze

  belongs_to :settlement
  belongs_to :drink

  validates :amount, presence: true, numericality: true
  validates :price_in_cents, presence: true, numericality: true

  # Only a real change: Settlement#valid?(:email_delivery) re-validates unchanged loaded positions too.
  validate :settlement_must_be_draft, if: -> { new_record? || changed? }
  # A locked position keeps its price; re-pricing would make it look changed after a Drink price edit.
  before_validation :set_price_in_cents, unless: -> { persisted? && settlement_locked? }
  before_destroy :settlement_must_be_draft_for_destroy

  def drink_price_in_cents
    drink.price_in_cents_at(date: settlement.generated_at)
  end

  private

  def settlement_locked?
    settlement.present? && !settlement.draft?
  end

  def settlement_must_be_draft
    errors.add(:base, LOCKED_MESSAGE) if settlement_locked?
  end

  def settlement_must_be_draft_for_destroy
    return unless settlement_locked?

    errors.add(:base, LOCKED_MESSAGE)
    throw :abort
  end

  def set_price_in_cents
    return if drink.blank? || amount.blank?

    self.price_in_cents = amount * drink_price_in_cents
  end
end
