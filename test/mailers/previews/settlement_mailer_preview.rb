# Preview all emails at http://kiosk.localhost:3001/rails/mailers/settlement_mailer
class SettlementMailerPreview < ActionMailer::Preview
  def completed_mail
    SettlementMailer.with(settlement: Settlement.last).completed_mail
  end
end
