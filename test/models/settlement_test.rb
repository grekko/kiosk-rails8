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

    assert_nil settlement.paid_at
    assert_not settlement.paid_at_changed?

    settlement.reload
    assert settlement.draft?
    assert_nil settlement.paid_at
  end

  test "complete is rejected for a paid settlement and leaves completed_at unset" do
    settlement = create_settlement
    settlement.update!(aasm_state: "paid")

    assert_raises(AASM::InvalidTransition) { settlement.complete! }

    assert_nil settlement.completed_at
    assert_not settlement.completed_at_changed?
  end

  test "schedule_email_delivery returns false when the client has no email" do
    settlement = create_settlement(client: Client.create!(name: "No Mail-#{SecureRandom.hex(4)}"))

    assert_no_enqueued_emails do
      assert_equal false, settlement.schedule_email_delivery
    end
    assert_nil settlement.reload.email_sent_at
  end

  test "schedule_email_delivery refuses a draft" do
    settlement = create_settlement

    assert_no_enqueued_emails do
      assert_equal false, settlement.schedule_email_delivery
    end
    assert_includes settlement.errors[:base], "Only a completed or paid settlement can be emailed"
    assert_nil settlement.reload.email_sent_at
  end

  test "schedule_email_delivery works for a paid settlement" do
    settlement = create_settlement
    settlement.complete!
    settlement.mark_paid!

    assert_enqueued_emails 1 do
      assert settlement.schedule_email_delivery
    end
    assert_not_nil settlement.reload.email_sent_at
  end

  test "schedule_email_delivery returns false when the email was already sent" do
    sent_at = 1.day.ago.change(usec: 0)
    settlement = create_settlement
    settlement.complete!
    settlement.update!(email_sent_at: sent_at)

    assert_no_enqueued_emails do
      assert_equal false, settlement.schedule_email_delivery
    end
    assert_equal sent_at, settlement.reload.email_sent_at
  end

  test "schedule_email_delivery enqueues the completed mail and sets email_sent_at" do
    settlement = create_settlement
    settlement.complete!

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

  test "a draft can change its date, client and monthly report" do
    settlement = create_settlement

    assert settlement.update(generated_at: 1.day.ago, client: Client.create!(name: "Bob-#{SecureRandom.hex(4)}"), monthly_report: MonthlyReport.create!(title: "February"))
  end

  %w[completed paid].each do |state|
    test "a #{state} settlement refuses changes to its date, client and monthly report" do
      settlement = create_settlement
      settlement.update_column(:aasm_state, state)

      assert_not settlement.update(generated_at: 1.day.ago)
      assert_includes settlement.errors[:generated_at], Settlement::LOCKED_MESSAGE
      assert_not settlement.update(client: Client.create!(name: "Bob-#{SecureRandom.hex(4)}"))
      assert_not settlement.update(monthly_report: MonthlyReport.create!(title: "February"))
    end
  end

  test "setting the state back to draft in the same save does not unlock it" do
    settlement = create_settlement
    settlement.complete!

    assert_not settlement.update(aasm_state: "draft", generated_at: 1.day.ago)
  end

  test "a completed settlement with positions still gets marked paid, emailed and linked to a payment" do
    settlement = create_settlement
    settlement.positions.create!(drink: Drink.create!(name: "Beer-#{SecureRandom.hex(4)}", price_in_cents: 150), amount: 2)
    settlement.complete!

    assert_enqueued_emails 1 do
      assert settlement.schedule_email_delivery
    end
    assert_not_nil settlement.reload.email_sent_at

    payment = Payment.create_for_client(settlement.client)

    settlement.reload
    assert settlement.paid?
    assert_not_nil settlement.paid_at
    assert_equal payment, settlement.payment
  end

  test "email delivery still works on a completed settlement after its drink price changed" do
    settlement = create_settlement
    drink = Drink.create!(name: "Beer-#{SecureRandom.hex(4)}", price_in_cents: 150)
    settlement.positions.create!(drink:, amount: 2)
    settlement.complete!
    drink.update!(price_in_cents: 999)

    settlement = Settlement.includes(:positions).find(settlement.id)

    assert settlement.schedule_email_delivery
    assert_equal 300, settlement.reload.price_in_cents
  end

  test "mark_paid works on a completed settlement" do
    settlement = create_settlement
    settlement.complete!

    settlement.mark_paid!

    assert settlement.reload.paid?
  end

  test "reopen moves a completed settlement back to draft and clears completed_at" do
    settlement = create_settlement
    settlement.complete!

    settlement.reopen!

    settlement.reload
    assert settlement.draft?
    assert_nil settlement.completed_at
    assert settlement.update(generated_at: 1.day.ago)
  end

  test "reopen is refused for a paid settlement" do
    settlement = create_settlement
    settlement.complete!
    settlement.mark_paid!

    assert_raises(AASM::InvalidTransition) { settlement.reopen! }

    assert settlement.reload.paid?
  end

  test "reopen is refused once the email was sent" do
    settlement = create_settlement
    settlement.complete!
    settlement.update!(email_sent_at: Time.current)

    assert_not settlement.may_reopen?
    assert_raises(AASM::InvalidTransition) { settlement.reopen! }

    settlement.reload
    assert settlement.completed?
    assert_not_nil settlement.completed_at
  end

  private

  def create_settlement(client: Client.create!(name: "Alice-#{SecureRandom.hex(4)}", email: "alice@example.com"))
    Settlement.create!(client:, monthly_report: MonthlyReport.create!(title: "January"), generated_at: Date.current)
  end
end
