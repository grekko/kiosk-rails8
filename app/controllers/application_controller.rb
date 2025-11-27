class ApplicationController < ActionController::Base
  include ActiveStorage::SetCurrent

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  http_basic_authenticate_with name: "kiosk", password: "sup3r-s3cr37"
end
