require('nokogiri')

class Parse

  def self.get(dom, css, size)
    possible_array = dom.css(css)
    if (possible_array.size != size) 
      raise "Expected #{size} elements " + possible_array.to_s
    end
    possible_array
  end

  def self.load
    if (Player.count > 0)
      raise "Already loaded"
    end
    sorted = Dir.glob("#{Cache.location}/*.html").sort do |a, b|
      File.basename(a, ".html").to_i <=> File.basename(b, ".html").to_i
    end
    
    players = []
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
        if player_link.next_sibling.text =~ /^\*?, ([A-Za-z]+) ([A-Za-z\/]+)$/
          player.team = $1
          player.position = $2
          player.name = player_link.text
        elsif player_link.next_sibling.text =~ /^ (D\/ST)$/
          player.position = $1
          player.team = "LOOKUP"
          if player_link.text =~ /^(.*) D\/ST$/
            player.name = $1
          else
            raise "Did not match " + player_link.text
          end
        else
          raise "Did not match " + filename + " " + player_link.next_sibling.text
        end
        players << player
      end
    end
    ActiveRecord::Base.transaction do
      players.each do |player|
        player.save!
      end
    end
    nil
  end

end




