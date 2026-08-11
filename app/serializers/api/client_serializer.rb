class Api::ClientSerializer
  def self.call(client)
    {
      id: client.id,
      name: client.name,
      email: client.email,
      suspended: client.suspended?
    }
  end
end
