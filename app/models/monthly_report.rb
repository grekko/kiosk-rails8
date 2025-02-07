class MonthlyReport < ApplicationRecord
  has_many :settlements
  has_one_attached :image

  def complete_settlements!
    settlements.draft.find_each do |settlement|
      settlement.complete!
    end
  end
end
