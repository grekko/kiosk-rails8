class External::MonthlyReportsController < External::BaseController
  def show
    @client = Client.find_by!(access_uuid: params[:client_access_uuid])
    @report = MonthlyReport.find(params[:id])
  end
end
