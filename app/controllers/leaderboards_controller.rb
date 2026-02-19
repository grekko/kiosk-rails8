class LeaderboardsController < ApplicationController
  def index
    @leaderboards = Leaderboard.call
  end
end
