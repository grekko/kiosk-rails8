class SettlementsController < ApplicationController
  before_action :set_settlement, only: %i[ edit update destroy complete reopen schedule_email ]

  def index
    @settlements = Settlement.includes(:client, :monthly_report).newest_first
  end

  def filtered
    @client = Client.find(params[:client_id])
    @settlements = Settlement.where(client: @client).includes(:client, :monthly_report).newest_first
  end

  def new
    @settlement = Settlement.new(
      {
        generated_at: Time.current,
        monthly_report_id: params[:monthly_report_id],
        client_id: params[:client_id]
      }.compact_blank
    )
  end

  def edit
  end

  def create
    @settlement = Settlement.new(settlement_params)

    if @settlement.save
      redirect_to edit_settlement_path(@settlement)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @settlement.update(settlement_params)
      redirect_to edit_settlement_path(@settlement)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def complete
    return redirect_to edit_settlement_path(@settlement), alert: "Only a draft settlement can be completed." unless @settlement.may_complete?

    @settlement.complete!
    redirect_to settlements_path
  end

  def reopen
    if @settlement.may_reopen?
      @settlement.reopen!
      flash[:notice] = "Settlement moved back to draft."
    else
      flash[:alert] = "A paid or emailed settlement can't be moved back to draft."
    end

    redirect_to edit_settlement_path(@settlement)
  end

  def schedule_email
    if @settlement.schedule_email_delivery
      flash[:notice] = "Email sent."
    else
      flash[:alert] = @settlement.errors.full_messages.to_sentence
    end

    redirect_back_or_to settlements_path
  end

  def destroy
    @settlement.destroy! if @settlement.draft?

    redirect_to settlements_path
  end

  private

  def set_settlement
    @settlement = Settlement.find(params.expect(:id))
  end

  def settlement_params
    params.expect(settlement: [ :client_id, :generated_at, :paid_at, :monthly_report_id ])
  end
end
