class Leaderboard
  def self.call
    new.call
  end

  def call
    # fetch raw data: { ["DrinkName", "ClientName"] => total_amount, ... }
    data = SettlementPosition
             .joins(:drink, settlement: :client)
             .where.not(settlements: { paid_at: nil })
             .group("drinks.name", "clients.name")
             .sum(:amount)

    # transform into { "DrinkName" => [ { client: "ClientName", count: 10 }, ... ], ... }
    leaderboards = data.each_with_object({}) do |((drink_name, client_name), count), hash|
      hash[drink_name] ||= []
      hash[drink_name] << { client: client_name, count: count }
    end

    # sort each drink's list by count descending
    leaderboards.each_value do |clients|
      clients.sort_by! { |entry| -entry[:count] }
    end

    # sort the drinks alphabetically
    leaderboards.sort.to_h
  end
end
