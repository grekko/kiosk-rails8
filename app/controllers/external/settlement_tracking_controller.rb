class External::SettlementTrackingController < External::BaseController
  def show
    settlement = Settlement.find_signed!(params[:id], purpose: :email_link)
    if settlement.email_first_opened_at.nil?
      settlement.update_column(:email_first_opened_at, Time.current)
      SettlementMailer.with(settlement: settlement).opened_notification.deliver_later
    end
    redirect_to external_client_url(settlement.client.access_uuid), allow_other_host: false
  end
end
