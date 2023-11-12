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
