class Client < ApplicationRecord
  has_many :settlements, -> { newest_first }
  has_many :payments, -> { newest_first }

  scope :active, -> { where(suspended_at: nil) }

  before_create :set_access_uuid

  validates :name, presence: true

  def suspended?
    suspended_at.present?
  end

  def suspend!
    update(suspended_at: Time.current)
  end

  def reinstate!
    update(suspended_at: nil)
  end

  def outstanding_payment_sum_in_cents
    payments.draft.sum(&:amount_in_cents)
  end

  private

  def set_access_uuid
    self.access_uuid = SecureRandom.uuid
  end
end
