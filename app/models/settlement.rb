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

    event :complete, after: %(set_completed_at schedule_email) do
      transitions from: :draft, to: :completed
    end

    event :mark_paid, after: :set_paid_at do
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

  def schedule_email
    return if email_sent_at? || client.email.blank?

    SettlementMailer.with(settlement: settlement).completed_mail.deliver_later
    update(email_sent_at: Time.current)
  end
end
