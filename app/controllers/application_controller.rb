class ApplicationController < ActionController::Base
  include ActiveStorage::SetCurrent

  AUTH_COOKIE_NAME = :kiosk_auth
  AUTH_COOKIE_VALUE = "kiosk".freeze
  AUTH_COOKIE_DURATION = 1.year

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :basic_auth

  def basic_auth
    return if authenticated_via_cookie?
    return if authenticate_with_http_basic { |user, password| handle_basic_auth(user, password) }

    request_http_basic_authentication
  end

  private

  def authenticated_via_cookie?
    cookies.signed[AUTH_COOKIE_NAME] == AUTH_COOKIE_VALUE
  end

  def handle_basic_auth(username, password)
    return false unless valid_authentication?(username, password)

    persist_auth_cookie
    true
  end

  def valid_authentication?(username, password)
    username == "kiosk" && password == "sup3r-s3cr37"
  end

  def persist_auth_cookie
    cookies.signed[AUTH_COOKIE_NAME] = {
      value: AUTH_COOKIE_VALUE,
      expires: AUTH_COOKIE_DURATION.from_now,
      httponly: true,
      same_site: :lax,
      secure: Rails.env.production?
    }
  end
end
