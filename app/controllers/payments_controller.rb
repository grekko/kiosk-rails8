class PaymentsController < ApplicationController
  def index
    @payments = Payment.newest_first.all
  end

  def new
    @client = Client.find(params.expect(:client_id))
    @payment = @client.payments.new(amount_in_cents: @client.outstanding_payment_sum_in_cents)
  end

  def create
    client = Client.find(params.expect(:client_id))
    amount = params.expect(payment: [ :amount_in_cents ])[:amount_in_cents].presence
    @payment = Payment.create_for_client(client, amount&.to_i)

    if @payment
      redirect_to clients_path, notice: "Payment recorded."
    else
      redirect_to new_client_payment_path(client), alert: "Amount too low to cover any settlement."
    end
  end
end
