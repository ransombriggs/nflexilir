module ApplicationHelper
  def conflict(player, bye)
    if (bye[player.position].include?(player.team.bye))
      "Y"
    else
      "&nbsp;"
    end.html_safe
  end

  def espn(player)
    "<a href=\"http://espn.go.com/nfl/player/_/id/#{player.player_id}\">#{player.player_id}</a>".html_safe
  end
end
