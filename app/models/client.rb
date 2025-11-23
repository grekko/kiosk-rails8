class Client < ApplicationRecord
  has_many :settlements
  has_many :payments

  scope :active, -> { where(suspended_at: nil) }

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
end
