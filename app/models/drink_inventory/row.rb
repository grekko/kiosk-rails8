class DrinkInventory::Row
  include ActiveModel::Model

  attr_accessor :id, :name
  attr_accessor :ordered_count, :settled_count, :remaining_count
  attr_accessor :purchase_price, :selling_price
end
