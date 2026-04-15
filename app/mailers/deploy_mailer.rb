class DeployMailer < ApplicationMailer
  def booted(sha:)
    @sha = sha
    @host = Socket.gethostname
    @booted_at = Time.current
    to = ENV.fetch("DEPLOY_NOTIFICATION_TO") { ApplicationMailer.default_params[:from] }
    mail(to: to, subject: "Kiosk deployed #{sha}")
  end
end
