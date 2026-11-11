# frozen_string_literal: true

Sentry.init do |config|
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]
  config.dsn = ENV["SENTRY_DSN"]
  # Baked into the image at build time as the short git SHA, so Sentry can
  # attribute an error to the deploy it came from.
  config.release = ENV["KIOSK_SHA"]
  config.traces_sample_rate = 1.0

  # Add data like request headers and IP for users: the gem's full defaults,
  # which is what the deprecated `send_default_pii = true` produced (sentry-ruby
  # 7.2), see https://docs.sentry.io/platforms/ruby/data-management/data-collected/
  config.data_collection = Sentry::DataCollection.new
end
