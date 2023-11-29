class CatnoController < ApplicationController
  
def search
  #Looking if it's coming from artist page
  if params.key?("artist_search")
    @dirty_catno = params.fetch("artist_search")
    @catno = params.fetch("artist_search").to_s.upcase.gsub(/\s+/, '').to_s
  else 
    #Getting catalogue number from search bar
    @dirty_catno = params.fetch("catno")
    @catno = params.fetch("catno").to_s.upcase.gsub(/\s+/, '').to_s
  end 

  #Retreiving data from Discogs
  $discogs_key = ENV.fetch("DISCOGS_KEY")
  $discogs_secret = ENV.fetch("DISCOGS_SECRET")
  $discogs_token = ENV.fetch("DISCOGS_TOKEN")
  @discogs_url = "https://api.discogs.com/database/search?type=release&format=vinyl&catno=#{@catno}&key=#{$discogs_key}&secret=#{$discogs_secret}&per_page=100"
  raw_discogs_data = HTTP.get(@discogs_url)
  parsed_discogs_data = JSON.parse(raw_discogs_data)
  @unfiltered_results = parsed_discogs_data.fetch("results")
  $query_total_results = parsed_discogs_data.fetch("pagination").fetch("items").to_i
  @unfiltered_results.each do |a_hash|
    a_hash["catno"] = a_hash["catno"].to_s
    a_hash["catno"].gsub!(/\s+/, '') 
    a_hash["catno"].upcase! if a_hash["catno"] 
    a_hash["master_id"] = a_hash["master_id"].to_i
  end
  $results_array = @unfiltered_results.select do |a_hash|
    a_hash["master_id"] != 0  && a_hash.key?("year") && a_hash["catno"] == @catno
  end
  pagination_hash = parsed_discogs_data.fetch("pagination")

  #Results array test:
  #render(template: "general/test")

  #Redirecting if search is not found 
  if $results_array.empty?
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
       redirect_to "/search/catno/findpressing/#{@master_ids.uniq.at(0)}"
      end

    #redirectioning if there is only one release
    else
      @record_id = $results_array.at(0).fetch("id")
      redirect_to "/search/catno/pressing/#{@record_id}"
    end 
  end 
end 




#End for entire controller
end 
