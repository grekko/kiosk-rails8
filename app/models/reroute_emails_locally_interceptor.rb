class RerouteEmailsLocallyInterceptor
  def self.delivering_email(mail)
    mail.to = "igelmund@grekko.de"
  end
end
