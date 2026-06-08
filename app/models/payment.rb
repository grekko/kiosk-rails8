class Payment < ApplicationRecord
  include AASM

  belongs_to :client
  has_many :settlements, -> { newest_first }, dependent: :nullify

  after_create :mark_settlements_paid

  scope :newest_first, -> { order(id: :desc) }

  def self.create_for_client(client, amount_in_cents = nil)
    candidates = client.settlements.completed.where.missing(:payment)
                       .includes(:positions).reorder(generated_at: :asc) # oldest debt first
    amount_in_cents ||= candidates.sum(&:price_in_cents)                  # nil ⇒ pay everything

    selected = []
    running = 0
    candidates.each do |settlement|
      break if running + settlement.price_in_cents > amount_in_cents      # ignore-leftover
      running += settlement.price_in_cents
      selected << settlement
    end
    return nil if selected.empty?                                         # amount too low

    record = new(client: client, settlements: selected, amount_in_cents: running)
    record.save
    record
  end

  private

  def mark_settlements_paid
    settlements.find_each(&:mark_paid!)
  end
end
