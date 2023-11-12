class CatnoController < ApplicationController
  
def search
  #Getting catalogue number
  @dirty_catno = params.fetch("catno")
  @catno = params.fetch("catno").to_s.upcase.gsub(/\s+/, '').to_s

  #Retreiving data from Discogs
  $discogs_key = ENV.fetch("DISCOGS_KEY")
  $discogs_secret = ENV.fetch("DISCOGS_SECRET")
  $discogs_token = ENV.fetch("DISCOGS_TOKEN")
  @discogs_url = "https://api.discogs.com/database/search?type=release&format=vinyl&catno=#{@catno}&key=#{$discogs_key}&secret=#{$discogs_secret}&per_page=100"
  raw_discogs_data = HTTP.get(@discogs_url)
  parsed_discogs_data = JSON.parse(raw_discogs_data)
  @unfiltered_results = parsed_discogs_data.fetch("results")
  @unfiltered_results.each do |a_hash|
    a_hash["catno"] = a_hash["catno"].to_s
    a_hash["catno"].gsub!(/\s+/, '') 
    a_hash["catno"].upcase! if a_hash["catno"] 
    a_hash["master_id"] = a_hash["master_id"].to_i
  end
  $results_array = @unfiltered_results.select do |a_hash|
    a_hash["master_id"] != 0  && a_hash.key?("year") && a_hash["catno"] == @catno
  end
  
  first_result_hash = $results_array.at(0)
  pagination_hash = parsed_discogs_data.fetch("pagination")

  #Results array test:
  #render(template: "general/test")

  #Redirecting if search is not found 
  if first_result_hash.nil?
    redirect_to "/notfound"
  else 
    #calculating number of pressings
    @num_pressings = $results_array.count { |element| element.is_a?(Hash) }

    #determining whether there are multiple masters, pressings, or if it's a single pressing
    if @num_pressings > 1
      @master_ids = []
      $results_array.each do |item|
        master = item.fetch("master_id")
        @master_ids << master
      end

      #redirectioning based on wheter there are multiple masters
      $num_masters = @master_ids.uniq.length
      if $num_masters > 1
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

  first_masters = {}
  @masters_list = $results_array.select do |hash|
    master_id = hash["master_id"]
    if master_id != 0 && !first_masters.key?(master_id)
      first_masters[master_id] = true
      true
    else
      false
    end
  end
  render(template: "catno/catno_multreleases")
end 

def findpressing
  #Retrieving master and catno from URL
  @master_id = params.fetch("masterid").to_i
  @catno = params.fetch("catno")

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

  render(template: "catno/catno_findpressing")
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

def explore
  #Getting master id and catno from URL
  @master_id = params.fetch("masterid").to_i
  @catno = params.fetch("catno")

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

  #Filtering results array for results that match master id and catno
  @filtered_results = $results_array.select do |hash|
    hash["master_id"] == @master_id
  end

  render(template: "catno/catno_explore")
end 

#End for entire controller
end 
