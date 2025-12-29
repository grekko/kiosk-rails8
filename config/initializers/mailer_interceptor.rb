Rails.application.configure do
  if Rails.env.development?
    config.action_mailer.interceptors = %w[RerouteEmailsLocallyInterceptor]
  end
end
