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
    settlement.complete!

    assert_no_enqueued_emails do
      assert_equal false, settlement.schedule_email_delivery
    end
    assert_equal [ "Client must have an email address" ], settlement.errors[:base]
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

  test "schedule_email_delivery sends no mail when email_sent_at can't be saved" do
    settlement = create_settlement
    settlement.complete!
    settlement.generated_at = 1.day.ago # locked once completed, so the save fails

    assert_no_enqueued_emails do
      assert_equal false, settlement.schedule_email_delivery
    end
    assert_nil settlement.reload.email_sent_at
  end

  test "two copies of one settlement, loaded before either sends, enqueue exactly one mail" do
    settlement = create_settlement
    settlement.complete!
    first = Settlement.find(settlement.id)
    second = Settlement.find(settlement.id)

    assert_enqueued_emails 1 do
      assert first.schedule_email_delivery
      assert_equal false, second.schedule_email_delivery
    end
    assert_equal [ "Email was already sent" ], second.errors[:base]
  end

  test "an enqueue error leaves email_sent_at nil and the settlement sendable" do
    settlement = create_settlement
    settlement.complete!

    with_failing_enqueue do
      assert_equal false, settlement.schedule_email_delivery
    end
    assert_equal [ "Email could not be queued, please try again" ], settlement.errors[:base]
    assert_nil settlement.reload.email_sent_at

    assert_enqueued_emails 1 do
      assert settlement.schedule_email_delivery
    end
    assert_not_nil settlement.reload.email_sent_at
  end

  test "any other enqueue error propagates and leaves the settlement sendable" do
    settlement = create_settlement
    settlement.complete!

    with_failing_enqueue(StandardError) do
      assert_raises(StandardError) { settlement.schedule_email_delivery }
    end
    assert_nil settlement.reload.email_sent_at
    assert settlement.valid?(:email_delivery)
  end

  test "price_in_cents runs no query when the positions are preloaded" do
    settlement = create_settlement
    drink = Drink.create!(name: "Beer-#{SecureRandom.hex(4)}", price_in_cents: 150)
    settlement.positions.create!(drink:, amount: 2)

    preloaded = Settlement.includes(:positions).find(settlement.id)

    assert_no_queries { assert_equal 2 * 150, preloaded.price_in_cents }
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

  # Makes the queue adapter raise error_class. Active Job turns ActiveJob::EnqueueError into a
  # false return from deliver_later; any other error (e.g. SolidQueue::Job::EnqueueError) propagates.
  def with_failing_enqueue(error_class = ActiveJob::EnqueueError)
    adapter = ActionMailer::MailDeliveryJob.queue_adapter
    adapter.define_singleton_method(:enqueue) { |*| raise error_class, "queue unavailable" }
    yield
  ensure
    adapter.singleton_class.remove_method(:enqueue)
  end

  def create_settlement(client: Client.create!(name: "Alice-#{SecureRandom.hex(4)}", email: "alice@example.com"))
    Settlement.create!(client:, monthly_report: MonthlyReport.create!(title: "January"), generated_at: Date.current)
  end
end
