class GeneralController < ApplicationController

def homepage
  placeholders = ["Unknown Pleasures | FACT10 | 0825646183906", "Purple Rain | RCV1 547450 | 081227880385", "All Things Must Pass | 3565241 | 602435652412", "Madvillainy | STH2065 | 659457206512", "Salad Days | CT-193 | 817949019471", "Schlagenheim | RT0073LP | 191402007312", "Titanic Rising | SP1232 | 098787123210", "In The Aeroplane Over The Sea | MRG136LP | 673855013619", "To Pimp a Butterfly | B0023464-01 | 602547311009", "Bonito Generation | PRC-375 | 644110037510"]

  placeholder_selection = placeholders[rand(0..9)]
  placeholder_items = placeholder_selection.split(" | ")
  @placeholder_name = placeholder_items[0]
  @placeholder_catno = placeholder_items[1]
  @placeholder_barcode = placeholder_items[2]
  
  render(template: "general/homepage")
end 

def notfound
  render(template: "general/notfound")
end 

def pressing
  #calling record id from URL
  @record_id = params.fetch("recordid").to_i
  @found_pressing = $results_array.find{ |hash| hash["id"] == @record_id }
 
    #finding other basic info about album
    @catno = @found_pressing.fetch("catno")
    @master_id = @found_pressing.fetch("master_id")
    @genre = @found_pressing.fetch("style").join(", ")
    @press_year = @found_pressing.fetch("year")
    @press_country = @found_pressing.fetch("country")
    @cover_url = @found_pressing.fetch("cover_image")
    @label = @found_pressing.fetch("label").uniq.sort.join(", ")
    
    if @found_pressing.fetch("formats").at(0).key?("text")
      @text = @found_pressing.fetch("formats").at(0).fetch("text")
    else 
      @text = "Standard Edition"
    end
  
    if @found_pressing.fetch("formats").at(0).fetch("descriptions").include?("Reissue")
        @release_type = "Reissue"
      elsif @found_pressing.fetch("formats").at(0).fetch("descriptions").include?("Repress")
        @release_type = "Repress"
      elsif @found_pressing.fetch("formats").at(0).fetch("descriptions").include?("Unofficial Release")
        @release_type = "Unofficial Release"
      elsif @found_pressing.fetch("formats").at(0).fetch("descriptions").include?("Mispress")
        @release_type = "Mispress"
     elsif @found_pressing.fetch("formats").at(0).fetch("descriptions").include?("Misprint")
      @release_type = "Misprint"
      elsif @found_pressing.fetch("formats").at(0).fetch("descriptions").include?("Special Edition")
        @release_type = "Special Edition"
      elsif @found_pressing.fetch("formats").at(0).fetch("descriptions").include?("Test Pressing")
        @release_type = "Test Pressing"
      else 
        @release_type = "First Pressing"
      end
  
  
    #External links:
    @discogs_buy_link = "https://www.discogs.com/sell/release/#{@record_id}?ev=rb"
    ebay_search_term = @artist.to_s+" "+@record.to_s+" "+@catno.to_s+" "+@press_year.to_s+" "+@text.to_s+" Vinyl"
    ebay_search_term_fixed = ebay_search_term.gsub(" ", "+")
    @ebay_search_link = "https://www.ebay.com/sch/i.html?_from=R40&_trksid=p4432023.m570.l1313&_nkw=#{ebay_search_term_fixed}&_sacat=0"
  
    #getting tracklist from API
    @discogs_url_release = "https://api.discogs.com/releases/#{@record_id}?&key=#{$discogs_key}&secret=#{$discogs_secret}"
    raw_discogs_data_release = HTTP.get(@discogs_url_release)
    @parsed_discogs_data_release = JSON.parse(raw_discogs_data_release)
    @tracklist = @parsed_discogs_data_release.fetch("tracklist")
    image_links = @parsed_discogs_data_release.fetch("images")
    @image_link_array = []
    image_links.each do |an_image|
      uri = an_image.fetch("uri")
      @image_link_array << uri
    end 
  
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

     #finding artist and record name from results array

     @artist = @parsed_discogs_data_release.fetch("artists").at(0).fetch("name")
     @record = @parsed_discogs_data_release.fetch("title")
  
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
  
end   


def findpressing
  #Retrieving master and catno from URL
  @master_id = params.fetch("masterid").to_i
  @catno = $results_array.at(0).fetch("catno")

  #Finding first record that matches master and catno for basic album info
  match_record = $results_array.find do |hash|
    hash["master_id"] == @master_id
  end 
  @cover_url = match_record.fetch("cover_image")

  #Breaking down artist name and record name
  title = match_record.fetch("title")
  artist_record = title.split(" - ")
  @artist = artist_record.at(0)
  @record = artist_record.at(1)

  #Getting options for dropdown menu
  @matching_hashes = $results_array.select do |hash|
    hash["master_id"] == @master_id
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

  render(template: "general/findpressing")
end 

def finding
  #getting each user selection from URL
  user_selection = params.fetch("user_selection")
  split_selection = user_selection.split(" | ")
  year_selection = split_selection[0]
  country_selection = split_selection[1]
  text_selection = split_selection[2]

  #finding pressing id
  if text_selection == "Standard Edition"
    @drop_selection = $results_array.find do |hash|
      hash["year"] == year_selection && 
      hash["country"] == country_selection &&
      !hash["formats"].any? { |format| format.key?("text") }
    end
  else 
    @drop_selection = $results_array.find do |hash|
      hash["year"] == year_selection && 
      hash["country"] == country_selection && 
      hash["formats"].any? { |format| format["text"] == text_selection } 
    end
  end 

  @selected_id = @drop_selection.fetch("id")

  #redirecting to results page
  redirect_to "/search/catno/pressing/#{@selected_id}"

end 


end 
