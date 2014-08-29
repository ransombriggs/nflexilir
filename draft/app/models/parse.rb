require('nokogiri')
require 'json'

class Parse

  def self.get(dom, css, size)
    possible_array = dom.css(css)
    if (possible_array.size != size) 
      raise "Expected #{size} elements " + possible_array.to_s
    end
    possible_array
  end

  def self.load
    if (Player.count > 0 || Team.count > 0)
      raise "Already loaded"
    end
    sorted = Dir.glob("#{Cache.location}/*.html").sort do |a, b|
      File.basename(a, ".html").to_i <=> File.basename(b, ".html").to_i
    end
    
    players = []
    team_data = JSON.parse(File.read("#{Rails.root}/data/teams.json"))
    teams = team_data["bye"].inject({}) do |acc, (name,bye)|
      team = Team.new
      team.name = name
      team.bye = bye

      acc[name] = team
      acc
    end

    sorted.each do |filename|
      f = File.open(filename)
      doc = Nokogiri::HTML(f)
      f.close
    
      doc.css("table.tableBody").each do |player_table|
        player_link = get(player_table, "span.subheadPlayerNameLink > nobr > a", 1)[0]
        player_link.attr("playerid")
        trs = get(player_table, "tr.tableBody", 2)
    
        player = Player.new
        player.player_id = player_link.attr("playerid").to_i
        player.stats = get(trs[0], "td.appliedPoints", 1)[0].text.to_f
        player.proj = get(trs[1], "td.appliedPoints", 1)[0].text.to_f
        player_link.previous_sibling.text =~ /^(\d+)\./
        player.rank = $1.to_i
        if player_link.next_sibling.text =~ /^\*?, ([A-Za-z]+) ([A-Za-z\/]+)$/
          team_name = $1
          player.position = $2
          player.name = player_link.text
        elsif player_link.next_sibling.text =~ /^ (D\/ST)$/
          player.position = $1
          if player_link.text =~ /^(.*) D\/ST$/
            if (team_data["defense"][$1])
              team_name = team_data["defense"][$1]
            else
              raise "Could not find #{$1} in team data"
            end
            player.name = $1
          else
            raise "Did not match " + player_link.text
          end
        else
          if "Dexter McCluster".eql?(player_link.text) || "MarQueis Gray".eql?(player_link.text)
            next
          else
            raise "Did not match " + filename + " " + player_link.next_sibling.text
          end
        end
        if (teams.keys.find{|team| team == team_name})
          player.team = teams[team_name]
        else
          raise "Could not find #{$team_name} in bye data"
        end
        players << player
      end
    end
    filename = "#{Cache.location}/players.json"
    File.open(filename, 'wb') {|f| f.write(players.to_json) }
    
    ActiveRecord::Base.transaction do
      teams.values.each do |team|
        team.save!
      end
      players.each do |player|
        player.save!
      end
    end
    
    nil
  end

  def self.load_tiers
    sorted = Dir.glob("#{Cache.location}/tiers/*.html")

    players = {}
    
    sorted.each do |filename|
      f = File.open(filename)
      doc = Nokogiri::HTML(f)
      f.close

      columns = nil
      baseline = 0
      tiers = []
      doc.css("tr").each do |player_row|
        if player_row['class'] == 'subtitle' 
          unless columns.nil?
            baseline += columns
          end
          columns = player_row.css("td").size
          columns.times do 
            tiers << []
          end
        end
        if player_row['class'] == 'row1' || player_row['class'] == 'row2'
          tds = player_row.css("td")
          (0..columns).each do |i|
            unless tds[i].nil?
              text = tds[i].text.strip
              unless text.eql?(" ")
                if players[text]
                  raise
                else 
                  players[text] = baseline + i
                end
                tiers[baseline + i] << text
              end
            end
          end
        end
      end
      puts JSON.pretty_generate(tiers)
    end
    filename = "#{Cache.location}/tiers.json"
    File.open(filename, 'wb') {|f| f.write(players.to_json) }
  end

end
