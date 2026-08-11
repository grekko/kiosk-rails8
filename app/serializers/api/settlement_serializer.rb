class Api::SettlementSerializer
  def self.call(settlement)
    {
      id: settlement.id,
      state: settlement.aasm_state,
      client_id: settlement.client_id,
      client_name: settlement.client.name,
      monthly_report_id: settlement.monthly_report_id,
      monthly_report_title: settlement.monthly_report.title,
      generated_at: settlement.generated_at&.iso8601,
      completed_at: settlement.completed_at&.iso8601,
      paid_at: settlement.paid_at&.iso8601,
      email_sent_at: settlement.email_sent_at&.iso8601,
      email_first_opened_at: settlement.email_first_opened_at&.iso8601,
      price_in_cents: settlement.price_in_cents,
      positions: settlement.positions.map { |position| Api::SettlementPositionSerializer.call(position) }
    }
  end
end
