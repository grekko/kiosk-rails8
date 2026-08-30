require "test_helper"

class ClientTest < ActiveSupport::TestCase
  setup do
    @client = Client.create!(name: "Alice-#{SecureRandom.hex(4)}")
    @report = MonthlyReport.create!(title: "January")
    @drink = Drink.create!(name: "Pils-#{SecureRandom.hex(4)}", price_in_cents: 120)
  end

  test "requires a name" do
    assert_not Client.new.valid?
  end

  test "gets an access uuid on creation" do
    assert_match(/\A[0-9a-f-]{36}\z/, @client.access_uuid)
  end

  test "email must be unique but may be blank for several clients" do
    Client.create!(name: "Bob", email: "shared@example.com")

    assert_not Client.new(name: "Carol", email: "shared@example.com").valid?
    assert Client.new(name: "Dave").valid?
  end

  test "suspending and reinstating flips the active scope" do
    assert_includes Client.active, @client

    @client.suspend!

    assert @client.suspended?
    assert_not_includes Client.active, @client

    @client.reinstate!

    assert_not @client.suspended?
    assert_includes Client.active, @client
  end

  test "with_email only lists clients that have one" do
    with_email = Client.create!(name: "Bob", email: "bob-#{SecureRandom.hex(4)}@example.com")

    assert_includes Client.with_email, with_email
    assert_not_includes Client.with_email, @client
  end

  test "outstanding sum counts completed settlements only" do
    completed_settlement(2)   # 240
    draft_settlement(5)       # not counted, still a draft

    assert_equal 240, @client.outstanding_payment_sum_in_cents
  end

  test "outstanding sum drops a settlement once it is paid" do
    completed_settlement(2)
    completed_settlement(3)

    assert_equal 600, @client.outstanding_payment_sum_in_cents

    Payment.create_for_client(@client, 240)

    assert_equal 360, @client.outstanding_payment_sum_in_cents
  end

  test "a client without settlements owes nothing" do
    assert_equal 0, @client.outstanding_payment_sum_in_cents
  end

  private

  def draft_settlement(amount)
    settlement = Settlement.create!(client: @client, monthly_report: @report, generated_at: Date.current)
    settlement.positions.create!(drink: @drink, amount: amount)
    settlement
  end

  def completed_settlement(amount)
    draft_settlement(amount).tap(&:complete!)
  end
end
