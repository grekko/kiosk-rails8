class PaymentsController < ApplicationController
  def index
    @payments = Payment.newest_first.all
  end

  def create
    client = Client.find(params.expect(:client_id))
    @payment = Payment.create_for_client(client)

    redirect_back_or_to clients_path
  end
end
