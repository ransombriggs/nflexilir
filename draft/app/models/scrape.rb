require('rubygems')
require('nokogiri')
require('net/http')
require('cgi')

class Scrape

  def self.scrape(cookie)

    uri = URI("http://games.espn.go.com/ffl/tools/projections?display=alt&leagueId=591704&startIndex=0")
    
    while (uri)
      startIndex = CGI::parse(uri.query)["startIndex"][0]
      puts "Downloading #{startIndex}..."

      req = Net::HTTP::Get.new(uri)
      req["Cookie"] = cookie
      res = Net::HTTP.start(uri.hostname, uri.port) {|http|
          http.request(req)
      }
  
      filename = "#{Cache.location}/#{startIndex}.html"
      File.open(filename, 'wb') {|f| f.write(res.body) }
  
      f = File.open(filename)
      doc = Nokogiri::HTML(f)
      f.close
  
      next_link = doc.css("div.paginationNav > a").find {|x| x.text == "NEXT»"}
      if (next_link.nil?)
        break
      end
  
      uri = URI(next_link['href'])
    end
  end
end
