class Api::BaseController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  # Payloads are documented explicitly in docs/api.md — no implicit wrapping,
  # which would silently drop nested keys such as `positions`.
  wrap_parameters false

  before_action :authenticate_api_client

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
  rescue_from ActionController::ParameterMissing, with: :render_parameter_missing
  rescue_from AASM::InvalidTransition, with: :render_invalid_transition

  # Reading the token through a class method keeps credential lookup in one
  # place and makes it easy to stub in tests.
  def self.api_token
    Rails.application.credentials.dig(:api, :token)
  end

  private

  def authenticate_api_client
    return render_unconfigured if self.class.api_token.blank?
    return if authenticate_with_http_token { |token, _options| valid_token?(token) }

    render_error(
      "unauthorized",
      "Provide the API token as `Authorization: Bearer <token>`.",
      :unauthorized
    )
  end

  def valid_token?(token)
    ActiveSupport::SecurityUtils.secure_compare(token.to_s, self.class.api_token.to_s)
  end

  def render_unconfigured
    render_error(
      "api_not_configured",
      "No API token is configured. Add `api.token` to the Rails credentials.",
      :service_unavailable
    )
  end

  def render_not_found(exception)
    render_error("not_found", exception.message, :not_found)
  end

  def render_record_invalid(exception)
    render_validation_errors(exception.record)
  end

  def render_parameter_missing(exception)
    render_error("parameter_missing", exception.message, :bad_request)
  end

  def render_invalid_transition(exception)
    render_error("invalid_transition", exception.message, :unprocessable_entity)
  end

  def render_validation_errors(record)
    render json: {
      error: "validation_failed",
      message: record.errors.full_messages.to_sentence,
      details: record.errors.to_hash(true)
    }, status: :unprocessable_entity
  end

  def render_error(error, message, status)
    render json: { error: error, message: message }, status: status
  end
end
