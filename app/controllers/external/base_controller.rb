class External::BaseController < ApplicationController
  skip_before_action :basic_auth
end
