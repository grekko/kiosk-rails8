class PaymentsController < ApplicationController
  before_action :set_client, only: %i[ new create ]
  before_action :set_payment, only: %i[ edit update mark_settled ]

  def index
    @payments = Payment.order(id: :desc).all
  end

  def new
    @payment = Payment.build_for_client(@client)
  end

  def edit
  end

  def create
    @payment = Payment.build_for_client(@client)
    @payment.assign_attributes(payment_params)

    if @payment.save
      redirect_to params[:return_to_path].presence || edit_payment_path(@payment)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @payment.update(payment_params)
      redirect_to edit_payment_path(@payment)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def mark_settled
    @payment.mark_settled!
    redirect_back fallback_location: payments_path
  end

  private

  def set_client
    @client = Client.find(params.expect(:client_id))
  end

  def set_payment
    @payment = Payment.find(params.expect(:id))
  end

  def payment_params
    params.expect(payment: [ :note ])
  end
end
