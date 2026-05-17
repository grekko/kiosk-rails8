class SettlementMailer < ApplicationMailer
  def opened_notification
    settlement = params[:settlement]
    @client = settlement.client
    mail to: "kiosk@grekko.de",
         subject: "Kiosk Mail [#{settlement.monthly_report.title}] geöffnet von #{@client.name}",
         body: "kt",
         content_type: "text/plain",
         message_stream: :outbound
  end

  def completed_mail
    @settlement = params[:settlement]
    @client = @settlement.client
    @report_title = @settlement.monthly_report.title

    mail to: @client.email,
         subject: "Comuna Kühlschrank Abrechnung [#{@report_title}]",
         track_opens: true,
         message_stream: :outbound
  end
end
