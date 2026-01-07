class Settlement < ApplicationRecord
  include AASM

  belongs_to :client
  belongs_to :monthly_report
  belongs_to :payment, optional: true
  has_many :positions, class_name: "SettlementPosition", dependent: :destroy

  scope :newest_first, -> { order(generated_at: :desc) }
  scope :unpaid, -> { where(aasm_state: %w[draft completed]) }

  validates :generated_at, presence: true

  with_options on: :email_delivery do
    validates :email_sent_at, absence: true
    validate :client_must_have_email
  end

  aasm do
    state :draft, initial: true
    state :completed
    state :paid

    event :complete, after: %(set_completed_at) do
      transitions from: :draft, to: :completed
    end

    event :mark_paid, after: :set_paid_at do
      transitions from: :completed, to: :paid
    end
  end

  def price_in_cents
    positions.sum(:price_in_cents)
  end

  def schedule_email_delivery
    return false unless valid?(:email_delivery)

    SettlementMailer.with(settlement: self).completed_mail.deliver_later
    update(email_sent_at: Time.current)
  end

  private

  def client_must_have_email
    return true if client.email.present?

    errors.add(:base, "Client must have an email address")
  end

  def set_completed_at
    self.completed_at ||= Time.current
  end

  def set_paid_at
    self.paid_at ||= Time.current
  end
end
