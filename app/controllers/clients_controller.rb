class ClientsController < ApplicationController
  before_action :set_client, only: %i[ edit update suspend reinstate ]

  def index
    @clients = Client.all.order(suspended_at: :asc)
  end

  def new
    @client = Client.new
  end

  def edit
  end

  def create
    @client = Client.new(client_params)

    if @client.save
      redirect_to clients_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @client.update(client_params)
      redirect_to clients_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def suspend
    @client.suspend!
    redirect_to clients_path
  end

  def reinstate
    @client.reinstate!
    redirect_to clients_path
  end

  private

  def set_client
    @client = Client.find(params.expect(:id))
  end

  def client_params
    params.expect(client: [ :name, :email ])
  end
end
