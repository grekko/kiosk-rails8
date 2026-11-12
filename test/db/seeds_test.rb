require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  SEEDS = Rails.root.join("db/seeds.rb")

  test "development gets the example data once, without sending mail" do
    as_development do
      assert_no_enqueued_emails { load SEEDS }
      assert_example_data

      load SEEDS
      assert_example_data
    end
  end

  test "other environments get nothing" do
    load SEEDS

    assert_equal 0, Drink.count
    assert_equal 0, Client.count
  end

  private

  def assert_example_data
    assert_equal 4, Drink.count
    assert Drink.all.all?(&:current_settlement_price)

    assert_equal 4, Client.count
    assert_equal 1, Client.where.not(suspended_at: nil).count
    assert_equal 1, Client.where(email: nil).count

    assert_equal 1, MonthlyReport.count
    assert_equal %w[completed draft paid], Settlement.order(:aasm_state).pluck(:aasm_state)
    assert_equal 1, Payment.count
  end

  def as_development
    original = Rails.method(:env)
    Rails.define_singleton_method(:env) { ActiveSupport::EnvironmentInquirer.new("development") }

    yield
  ensure
    Rails.define_singleton_method(:env, original)
  end
end
