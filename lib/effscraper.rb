require 'nokogiri'
require 'open-uri'
require 'json'
require 'uploadconvert'

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
          dochash[:url] = a["href"]
          `wget -P public/uploads #{dochash[:url]}` 
          path = dochash[:url].split("/")
          dochash[:path] = "public/uploads/" + path[path.length-1].chomp.strip
        end
      end

      # Get date and title                                                      
      dochash[:doc_date] = l.css("span.date-display-single").text
      dochash[:title] = l.css("a")[1].text

      # Extract metadata and text
      begin
        u = UploadConvert.new(dochash[:path])
        metadata = u.extractMetadataPDF
        metadata.each{|k, v| dochash[k] = v}
        dochash[:text] = u.detectPDFType
        @casearray.push(dochash)
      rescue
      end
    end
  end
end
