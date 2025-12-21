class External::ClientController < External::BaseController
  def show
    @client = Client.find_by!(access_uuid: params[:access_uuid])
  end
end
