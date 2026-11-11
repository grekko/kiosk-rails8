# frozen_string_literal: true

Sentry.init do |config|
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]
  config.dsn = ENV["SENTRY_DSN"]
  # Baked into the image at build time as the short git SHA, so Sentry can
  # attribute an error to the deploy it came from.
  config.release = ENV["KIOSK_SHA"]
  config.traces_sample_rate = 1.0

  # Collect request headers, IP and user data. A fresh DataCollection holds the
  # gem's full defaults; Sentry.init otherwise starts with a restricted one.
  config.data_collection = Sentry::DataCollection.new
end
