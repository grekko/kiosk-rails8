class Settlement < ApplicationRecord
  belongs_to :client

  has_many :positions, class_name: "SettlementPosition", dependent: :destroy
end
