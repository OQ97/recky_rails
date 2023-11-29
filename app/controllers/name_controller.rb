class NameController < ApplicationController

def search
  #Getting search text
  @text = params.fetch("searchtext")
  @redirect_text = @text.gsub(" ", "+")

  #Retreiving data from Discogs
  $discogs_key = ENV.fetch("DISCOGS_KEY")
  $discogs_secret = ENV.fetch("DISCOGS_SECRET")
  $discogs_token = ENV.fetch("DISCOGS_TOKEN")
  @discogs_url = "https://api.discogs.com/database/search?type=release&format=vinyl&release_title=#{@text.downcase}&key=#{$discogs_key}&secret=#{$discogs_secret}&per_page=100"
  raw_discogs_data = HTTP.get(@discogs_url)
  parsed_discogs_data = JSON.parse(raw_discogs_data)
  @unfiltered_results = parsed_discogs_data.fetch("results")
  $query_total_results = parsed_discogs_data.fetch("pagination").fetch("items").to_i
  @unfiltered_results.each do |a_hash|
    a_hash["title"] = a_hash["title"].to_s
    a_hash["master_id"] = a_hash["master_id"].to_i
  end
  $results_array = @unfiltered_results.select do |a_hash|
   a_hash["master_id"] != 0  && a_hash.key?("year")
  end

  first_result_hash = $results_array.at(0)

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
        redirect_to "/search/multreleases/#{@master_ids.uniq.at(0)}"
      else
        @master_id = @master_ids.uniq.at(0) 
       redirect_to "/search/findpressing/#{@master_ids.uniq.at(0)}"
      end

    #redirectioning if there is only one release
    else
      @record_id = $results_array.at(0).fetch("id")
      redirect_to "/search/pressing/#{@record_id}"
    end 
  end 

end 

def multreleases
  render(template: "name/name_multreleases")
end 

def findpressing
  render(template: "name/name_findpressing")
end 

#End for controller
end 
