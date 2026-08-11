module ApplicationHelper
  STATUS_EMOJI = {
    "draft" => "📝",
    "completed" => "✅",
    "paid" => "💶"
  }.freeze

  def settlement_status_emoji(settlement)
    status_emoji(settlement.aasm_state)
  end

  def monthly_report_status_emoji(monthly_report)
    status_emoji(monthly_report.state)
  end

  def status_emoji(state)
    state = state.to_s
    label = state.humanize
    content_tag(
      :span,
      STATUS_EMOJI.fetch(state, state),
      title: label,
      "aria-label": label
    )
  end

  # A monthly report's attachment is usually a photo, but scans get uploaded as
  # PDFs — those render as a broken image in an <img>, so they get an <embed>
  # instead (same as the order invoice preview).
  def report_attachment_tag(attachment)
    return image_tag(attachment.url) unless attachment.content_type == "application/pdf"

    tag.embed(src: attachment.url, type: attachment.content_type, class: "report-attachment-pdf")
  end

  def formatted_price(price_in_cents)
    price = (price_in_cents / 100.to_f)
    number_to_currency(price, unit: "EUR", separator: ",", delimiter: "", format: "%n %u")
  end

  def formatted_date(date)
    return unless date

    date.to_date.iso8601
  end

  def formatted_datetime(datetime)
    return unless datetime

    datetime.in_time_zone("Europe/Berlin").strftime("%Y-%m-%d %H:%M")
  end

  def payment_message(payment)
    <<~MESSAGE
      Hallo #{payment.client.name},

      auf deinem Comuna-Bierdeckel stehen aktuell: #{formatted_price(payment.amount_in_cents)}.

      #{payment_drinks_lines(payment).join("\n")}

      #{payment_details(payment)}
    MESSAGE
  end

  def payment_details(payment)
    <<~MESSAGE
      Du kannst die Rechnung gerne per PayPal oder SEPA begleichen:
      #{paypal_payment_url(payment.amount_in_cents)}

      #{Rails.configuration.kiosk_iban}
    MESSAGE
  end

  def paypal_payment_url(amount_in_cents)
    "https://paypal.me/gregoryigelmund/#{(amount_in_cents / 100.to_f).round(2)}"
  end

  def epc_remittance(client_name, base_in_cents, total_in_cents)
    tip = total_in_cents - base_in_cents
    text = "Deckel #{client_name}"
    text += " + #{formatted_price(tip)} Trinkgeld" if tip.positive?
    text
  end

  def epc_qr_payload(amount_in_cents, remittance)
    amount = format("EUR%.2f", amount_in_cents / 100.0)
    [
      "BCD",
      "002",
      "1",
      "SCT",
      "",
      Rails.configuration.kiosk_beneficiary_name,
      Rails.configuration.kiosk_iban,
      amount,
      "",
      "",
      remittance.to_s[0, 140]
    ].join("\n")
  end

  def epc_qr_image(amount_in_cents, remittance)
    payload = epc_qr_payload(amount_in_cents, remittance)
    png = RQRCode::QRCode.new(payload, level: :m).as_png(
      border_modules: 4,     # quiet zone — required for scanners
      module_px_size: 8,     # crisp resolution
      color: "black",
      fill: "white"          # opaque white bg keeps contrast in dark mode
    )
    image_tag(png.to_data_url, alt: "EPC-QR-Code", class: "epc-qr")
  end

  def rounded_up_full_euro_in_cents(amount_in_cents)
    amount = amount_in_cents.to_i
    return 0 unless amount.positive?

    (amount + 1).ceildiv(100) * 100
  end

  def round_up_delta_in_cents(amount_in_cents)
    rounded_up_full_euro_in_cents(amount_in_cents) - amount_in_cents.to_i.clamp(0..)
  end

  def payment_drinks_lines(payment)
    payment.settlements.flat_map(&:positions).flat_map.each_with_object({}) do |position, hash|
      hash[position.drink.name] ||= { price_in_cents: position.drink_price_in_cents, amount: 0 }
      hash[position.drink.name][:amount] += position.amount
    end.map do |(name, details)|
      "#{details[:amount]} x #{name} (#{formatted_price(details[:price_in_cents])})"
    end
  end

  def lines_for_settlement(settlement)
    settlement.positions.map do |position|
      "#{position.amount} x #{position.drink.name} (#{formatted_price(position.drink_price_in_cents)})"
    end
  end

  def external?
    controller.class.ancestors.include?(External::BaseController)
  end
end
