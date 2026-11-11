# Development and test don't run jobs on Solid Queue, so its tables don't exist there.
# Loading its schema inside the test's transaction gives one test the tables; the rollback drops them.
module SolidQueueHelpers
  DELIVERY_ERROR = RuntimeError.new("Postmark is down")

  def load_solid_queue_tables
    ActiveRecord::Schema.verbose = false
    load Rails.root.join("db/queue_schema.rb")
  end

  # Queues the Settlement Email through Solid Queue as production does, then fails it.
  def fail_settlement_email(settlement, error = DELIVERY_ERROR)
    with_solid_queue { assert settlement.schedule_email_delivery }
    fail_last_job(error)
  end

  def with_solid_queue
    adapter = ActionMailer::MailDeliveryJob.queue_adapter
    ActionMailer::MailDeliveryJob.queue_adapter = ActiveJob::QueueAdapters::SolidQueueAdapter.new
    yield
  ensure
    ActionMailer::MailDeliveryJob.queue_adapter = adapter
  end

  # Records a failure the way a worker does after claiming the job.
  def fail_last_job(error = DELIVERY_ERROR)
    job = SolidQueue::Job.last
    job.ready_execution.destroy!
    job.failed_with(error)
    job
  end
end
