class Settlement < ApplicationRecord
  include AASM

  belongs_to :client
  belongs_to :monthly_report
  belongs_to :payment, optional: true
  has_many :positions, class_name: "SettlementPosition", dependent: :destroy

  scope :newest_first, -> { order(generated_at: :desc) }

  validates :generated_at, presence: true

  aasm do
    state :draft, initial: true
    state :completed
    state :paid

    event :complete, before: :set_completed_at do
      transitions from: :draft, to: :completed
    end

    event :mark_paid, before: :set_paid_at do
      transitions from: :completed, to: :paid
    end
  end

  def price_in_cents
    positions.sum(:price_in_cents)
  end

  private

  def set_completed_at
    self.completed_at ||= Time.current
  end

  def set_paid_at
    self.paid_at ||= Time.current
  end
end
