class Api::ClientsController < Api::BaseController
  def index
    clients = Client.order(:name)
    clients = clients.active if ActiveModel::Type::Boolean.new.cast(params[:active])

    render json: { clients: clients.map { |client| Api::ClientSerializer.call(client) } }
  end
end
