class ApplicationController < ActionController::Base
  include ActiveStorage::SetCurrent

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :basic_auth

  def basic_auth
    return if authenticate_with_http_basic { |user, password| valid_authentication?(user, password) }

    request_http_basic_authentication
  end

   def valid_authentication?(username, password)
    username == "kiosk" && password == "sup3r-s3cr37"
  end
end
