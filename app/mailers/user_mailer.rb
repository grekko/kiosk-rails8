class UserMailer < ApplicationMailer
  def payment_email
    mail to: "igelmund@grekko.de",
      subject: "Welcome to My Awesome Site",
      track_opens: true,
      message_stream: :outbound
  end
end
