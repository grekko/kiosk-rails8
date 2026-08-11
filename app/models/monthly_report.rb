class MonthlyReport < ApplicationRecord
  STATES = %w[ draft completed ].freeze

  has_many :settlements
  has_one_attached :image

  scope :draft, -> { where(completed_at: nil) }
  scope :completed, -> { where.not(completed_at: nil) }

  # Unknown states return nothing, mirroring the settlement state filter.
  scope :by_state, ->(state) { STATES.include?(state.to_s) ? public_send(state.to_s) : none }

  def state
    completed? ? "completed" : "draft"
  end

  def completed?
    completed_at.present?
  end

  # Completing is a manual marker, set once every settlement of the report
  # exists; there is no automatic transition and it can be undone. Completing an
  # already completed report keeps the original timestamp.
  def complete!
    update(completed_at: completed_at || Time.current)
  end

  def reopen!
    update(completed_at: nil)
  end

  def overall_amount
    settlements.flat_map(&:positions).sum(&:amount)
  end

  def complete_settlements!
    settlements.draft.find_each do |settlement|
      settlement.complete!
    end
  end

  def schedule_settlement_emails!
    settlements.where.not(aasm_state: :draft).includes(:client).find_each.count(&:schedule_email_delivery)
  end
end
