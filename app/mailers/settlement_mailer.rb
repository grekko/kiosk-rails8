class SettlementMailer < ApplicationMailer
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
