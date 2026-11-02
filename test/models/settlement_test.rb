require "test_helper"

class SettlementTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "complete moves a draft to completed and sets completed_at" do
    settlement = create_settlement

    freeze_time do
      settlement.complete!

      settlement.reload
      assert settlement.completed?
      assert_equal Time.current, settlement.completed_at
    end
  end

  test "mark_paid is rejected for a draft settlement" do
    settlement = create_settlement

    assert_raises(AASM::InvalidTransition) { settlement.mark_paid! }

    settlement.reload
    assert settlement.draft?
    assert_nil settlement.paid_at
  end

  test "schedule_email_delivery returns false when the client has no email" do
    settlement = create_settlement(client: Client.create!(name: "No Mail-#{SecureRandom.hex(4)}"))

    assert_no_enqueued_emails do
      assert_equal false, settlement.schedule_email_delivery
    end
    assert_nil settlement.reload.email_sent_at
  end

  test "schedule_email_delivery returns false when the email was already sent" do
    sent_at = 1.day.ago.change(usec: 0)
    settlement = create_settlement
    settlement.update!(email_sent_at: sent_at)

    assert_no_enqueued_emails do
      assert_equal false, settlement.schedule_email_delivery
    end
    assert_equal sent_at, settlement.reload.email_sent_at
  end

  test "schedule_email_delivery enqueues the completed mail and sets email_sent_at" do
    settlement = create_settlement

    freeze_time do
      assert_enqueued_email_with SettlementMailer, :completed_mail, params: { settlement: } do
        assert settlement.schedule_email_delivery
      end
      assert_equal Time.current, settlement.reload.email_sent_at
    end
  end

  test "price_in_cents sums the positions" do
    settlement = create_settlement
    beer = Drink.create!(name: "Beer-#{SecureRandom.hex(4)}", price_in_cents: 150)
    mate = Drink.create!(name: "Mate-#{SecureRandom.hex(4)}", price_in_cents: 220)
    SettlementPosition.create!(settlement:, drink: beer, amount: 3)
    SettlementPosition.create!(settlement:, drink: mate, amount: 2)

    assert_equal 3 * 150 + 2 * 220, settlement.price_in_cents
  end

  private

  def create_settlement(client: Client.create!(name: "Alice-#{SecureRandom.hex(4)}", email: "alice@example.com"))
    Settlement.create!(client:, monthly_report: MonthlyReport.create!(title: "January"), generated_at: Date.current)
  end
end
