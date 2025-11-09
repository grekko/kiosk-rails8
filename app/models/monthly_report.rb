class MonthlyReport < ApplicationRecord
  has_many :settlements
  has_one_attached :image

  def overall_amount
    settlements.flat_map(&:positions).sum(&:amount)
  end

  def complete_settlements!
    settlements.draft.find_each do |settlement|
      settlement.complete!
    end
  end
end
