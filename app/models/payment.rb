class Payment < ApplicationRecord
  include AASM

  belongs_to :client
  has_many :settlements, -> { newest_first }, dependent: :nullify

  scope :newest_first, -> { order(id: :desc) }

  def self.build_for_client(client)
    record = new(client: client)
    record.settlements = client.settlements.completed.where.missing(:payment)
    record.amount_in_cents = record.settlements.sum(&:price_in_cents)
    record
  end

  aasm do
    state :draft, initial: true
    state :settled

    event :mark_settled, before: %i[set_settled_at mark_settlements_paid] do
      transitions from: :draft, to: :settled
    end
  end

  private

  def set_settled_at
    self.settled_at ||= Time.current
  end

  def mark_settlements_paid
    settlements.find_each(&:mark_paid!)
  end
end
