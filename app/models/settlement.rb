class Settlement < ApplicationRecord
  include AASM

  belongs_to :client
  belongs_to :monthly_report
  belongs_to :payment, optional: true
  has_many :positions, class_name: "SettlementPosition", dependent: :destroy

  scope :newest_first, -> { order(generated_at: :desc) }
  # Drafts may still change or be reopened, so the Client Page never shows them.
  scope :visible_to_client, -> { where(aasm_state: %w[completed paid]) }

  # Data that decides what the Client owes; frozen once the Settlement leaves draft.
  LOCKED_ATTRIBUTES = %w[generated_at client_id monthly_report_id].freeze
  LOCKED_MESSAGE = "can no longer be changed once the settlement is completed".freeze

  validates :generated_at, presence: true
  validate :locked_unless_draft, on: :update

  with_options on: :email_delivery do
    validates :email_sent_at, absence: true
    validate :client_must_have_email
    validate :must_not_be_draft
  end

  aasm do
    state :draft, initial: true
    state :completed
    state :paid

    event :complete do
      transitions from: :draft, to: :completed, after: :set_completed_at
    end

    event :mark_paid do
      transitions from: :completed, to: :paid, after: :set_paid_at
    end

    # Undoes a mistaken completion, but only before the Client saw the amount (email) or paid it.
    event :reopen do
      transitions from: :completed, to: :draft, guard: :email_not_sent?, after: :clear_completed_at
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

  # Checks the stored state, so setting aasm_state back to draft in the same save can't unlock it.
  def locked_unless_draft
    return if aasm_state_in_database == "draft"

    (changed & LOCKED_ATTRIBUTES).each { |attribute| errors.add(attribute, LOCKED_MESSAGE) }
  end

  def client_must_have_email
    return true if client.email.present?

    errors.add(:base, "Client must have an email address")
  end

  # A draft may still change and is hidden from the Client Page, so its email would link to nothing.
  def must_not_be_draft
    errors.add(:base, "Only a completed or paid settlement can be emailed") if draft?
  end

  def set_completed_at
    self.completed_at ||= Time.current
  end

  def email_not_sent?
    email_sent_at.blank?
  end

  def clear_completed_at
    self.completed_at = nil
  end

  def set_paid_at
    self.paid_at ||= Time.current
  end
end
