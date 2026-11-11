module QueryCountHelpers
  # Counts the SQL queries the block runs, so a test can show a page's count doesn't grow with its rows.
  def count_queries(&)
    count = 0
    counter = ->(*, payload) { count += 1 unless payload[:name] == "SCHEMA" || payload[:cached] }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &)
    count
  end
end
