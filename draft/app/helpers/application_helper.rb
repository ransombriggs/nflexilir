module ApplicationHelper
  def espn(player)
    "<a href=\"http://espn.go.com/nfl/player/_/id/#{player.player_id}\">#{player.player_id}</a>".html_safe
  end
end
