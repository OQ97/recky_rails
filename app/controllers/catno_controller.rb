class CatnoController < ApplicationController
  
def search
  #Getting catalogue number
  @catno = params.fetch("catno")

  #Retreiving data from Discogs
  $discogs_key = ENV.fetch("DISCOGS_KEY")
  $discogs_secret = ENV.fetch("DISCOGS_SECRET")
  $discogs_token = ENV.fetch("DISCOGS_TOKEN")
  @discogs_url = "https://api.discogs.com/database/search?type=release&format=vinyl&catno=#{@catno}&key=#{$discogs_key}&secret=#{$discogs_secret}"
  raw_discogs_data = HTTP.get(@discogs_url)
  parsed_discogs_data = JSON.parse(raw_discogs_data)
  $results_array = parsed_discogs_data.fetch("results")
  first_result_hash = $results_array.at(0)
  pagination_hash = parsed_discogs_data.fetch("pagination")

  #Redirecting if search is not found 
  if first_result_hash.nil?
    redirect_to "/notfound"
  else 
    #calculating number of pressings
    @num_pressings = pagination_hash.fetch("items").to_i

    #determining whether there are multiple masters, pressings, or if it's a single pressing
    if @num_pressings > 1
      @master_ids = []
      $results_array.each do |item|
        master = item.fetch("master_id").to_i
        @master_ids << master
      end

      #redirectioning based on wheter there are multiple masters
      @num_masters = @master_ids.uniq.length
      if @num_masters > 1
        redirect_to "/search/catno/multreleases/#{@catno}"
      else
        @master_id = @master_ids.uniq.at(0) 
        redirect_to "/search/catno/findpressing/#{@master_ids.uniq.at(0)}/#{@catno}"
      end

    #redirectioning if there is only one release
    else
      @record_id = $results_array.at(0).fetch("id")
      redirect_to "/search/catno/pressing/#{@record_id}"
    end 
  end 
end 

def multreleases
  @catno = params.fetch("catno")
  render(template: "catno/catno_multreleases")
end 

def findpressing
  #Retrieving master and catno from URL
  @master_id = params.fetch("masterid")
  @catno = params.fetch("catno")

  #Finding first record that matches master and catno for basic album info
  match_record = $results_array.find do |hash|
    hash["catno"] == @catno && hash["master_id"] == @master_id.to_i
  end 
  @cover_url = match_record.fetch("cover_image")

  #Breaking down artist name and record name
  title = match_record.fetch("title")
  artist_record = title.split(" - ")
  @artist = artist_record.at(0)
  @record = artist_record.at(1)

  #Finding first record that matches master and catno for basic album info
  @matching_hashes = $results_array.select do |hash|
   hash["catno"] == @catno && hash["master_id"] == @master_id.to_i
  end 

  @drop_hash = @matching_hashes.map do |hash|
    year = hash["year"]
    country = hash["country"]
    id = hash["id"]
    if hash["formats"].at(0).key?("text")
      format_text = hash["formats"].map { |format| format["text"] }.compact.join(", ")
    else
      format_text = "Standard Edition"
    end
    {
      "year" => year,
      "country" => country,
      "text" => format_text,
      "record_id" => id
    }
  end

  @drop_array = @drop_hash.map do |hash|
    "#{hash["year"]} | #{hash["country"]} | #{hash["text"]} | #{hash["record_id"]}"
  end

  @drop_array = @drop_array.map { |str| str.gsub('&', ' + ') }

  @drop_years = @drop_hash.map { |hash| hash["year"] }

  render(template: "catno/catno_findpressing")
end 

def pressing
  #calling record id from URL
  @record_id = params.fetch("recordid").to_i

  #finding pressing in results array from first serach
  @found_pressing = $results_array.find{ |hash| hash["id"] == @record_id }
  
  #finding artist and record name from results array
  title = @found_pressing.fetch("title")
  artist_record = title.split(" - ")
  @artist = artist_record.at(0)
  @record = artist_record.at(1)
  
  #finding other basic info about album
  @catno = @found_pressing.fetch("catno")
  @genre = @found_pressing.fetch("style").join(", ")
  @press_year = @found_pressing.fetch("year")
  @press_country = @found_pressing.fetch("country")
  @cover_url = @found_pressing.fetch("cover_image")
  @label = @found_pressing.fetch("label").join(", ")
  
  if @found_pressing.fetch("formats").at(0).key?("text")
    @text = @found_pressing.fetch("formats").at(0).fetch("text")
  else 
    @text = "Standard Edition"
  end

  #External links:
  @discogs_buy_link = "https://www.discogs.com/sell/release/#{@record_id}?ev=rb"
  ebay_search_term = @artist.to_s+" "+@record.to_s+" "+@catno.to_s+" "+@press_year.to_s+" "+@text.to_s+" Vinyl"
  ebay_search_term_fixed = ebay_search_term.gsub(" ", "+")
  @ebay_search_link = "https://www.ebay.com/sch/i.html?_from=R40&_trksid=p4432023.m570.l1313&_nkw=#{ebay_search_term_fixed}&_sacat=0"

  #getting tracklist from API
  @discogs_url_release = "https://api.discogs.com/releases/#{@record_id}"
  raw_discogs_data_release = HTTP.get(@discogs_url_release)
  @parsed_discogs_data_release = JSON.parse(raw_discogs_data_release)
  @tracklist = @parsed_discogs_data_release.fetch("tracklist")

  #Tracklist to table
  @html_table = "<table>\n"
  @html_table += "<tr><th>Position</th><th>Title</th><th>Duration</th></tr>\n"  # Table header row
  @tracklist.each do |track|
    @html_table += "<tr>"
    @html_table += "<td>#{track['position']}</td>"
    @html_table += "<td>#{track['title']}</td>"
    @html_table += "<td>#{track['duration']}</td>"
    @html_table += "</tr>\n"
  end
  @html_table += "</table>"

  #Retreiving price from API
  @prices_discogs_url = "https://api.discogs.com/marketplace/price_suggestions/#{@record_id}?&token=#{$discogs_token}"
  raw_discogs_price_data = HTTP.get(@prices_discogs_url)
  @parsed_discogs_price_data = JSON.parse(raw_discogs_price_data)

  if @parsed_discogs_price_data.fetch("Mint (M)").fetch("value").nil?
    @new = "N/A"
    @used_excellent = "N/A"
    @used_working = "N/A"
  else
    #getting prices for different conditions
    @mint = @parsed_discogs_price_data.fetch("Mint (M)").fetch("value")
    @near_mint = @parsed_discogs_price_data.fetch("Near Mint (NM or M-)").fetch("value")
    @Very_good_plus = @parsed_discogs_price_data.fetch("Very Good Plus (VG+)").fetch("value")
    @Very_good = @parsed_discogs_price_data.fetch("Very Good (VG)").fetch("value")
    @good_plus = @parsed_discogs_price_data.fetch("Good Plus (G+)").fetch("value")
    @good = @parsed_discogs_price_data.fetch("Good (G)").fetch("value")
    @fair = @parsed_discogs_price_data.fetch("Fair (F)").fetch("value")
    @poor = @parsed_discogs_price_data.fetch("Poor (P)").fetch("value")
    #calculating new prices
    @new = (@mint+@near_mint)/2
    @used_excellent = (@Very_good_plus+@Very_good)/2
    @used_working = (@good_plus+@good)/2
  end 
  
  render(template: "catno/catno_pressing")
end 

end 
