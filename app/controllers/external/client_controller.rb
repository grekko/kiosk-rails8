class External::ClientController < External::BaseController
  def show
    @client = Client.find_by!(access_uuid: params[:access_uuid])
    @settlements = @client.settlements.visible_to_client.includes(:monthly_report, positions: :drink)
  end
end
