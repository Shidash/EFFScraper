require 'nokogiri'
require 'open-uri'
require 'json'

class EFFScraper
  def initialize(url)
    @url = url
    @casearray = Array.new
  end

  # Scrapes all documents in case
  def scrapeCase
    html = Nokogiri::HTML(open(@url))

    # Get number of pages to scrape
    if html.css("li.pager-current")[0]
      count = html.css("li.pager-current")[0].text.split(" ")
      n = count[2].to_i
    else
      n = 1
    end

    # Go through pages and scrape them
    for i in 1..n
      if i > 1
        link = "https://eff.org" + html.css("li.pager-next")[0].css("a")[0]["href"]
        html = Nokogiri::HTML(open(link))
      end
      
      scrapePage(html)
    end
    
    JSON.pretty_generate(@casearray)
  end

  # Scrapes each page of documents
  def scrapePage(html)
    items = html.css("div.view-content")[0]
    
    items.css("li").each do |l|
      dochash = Hash.new

      # Gets link to document and file
      l.css("a").each do |a|
        if a.text == "[PDF]"
          dochash["url"] = a["href"]
          dochash["file"] = open(dochash["url"])
          # Get text of file with UpdateConvert
          # Get metadata of file with UpdateConvert
        end
      end

      # Gets date and title
      dochash["date"] = l.css("span.date-display-single").text
      dochash["title"] = l.css("a")[1].text
      @casearray.push(dochash)
    end
  end
end

e = EFFScraper.new("https://www.eff.org/cases/al-haramain")
puts e.scrapeCase
