class SearchController < ApplicationController

  def home
    render(template: "search/home")
  end 

  def search_catalogue
    #Getting catalogue number
    $catnum = params.fetch("catnum")

    #Retreiving data from Discogs
    $discogs_key = ENV.fetch("DISCOGS_KEY")
    $discogs_secret = ENV.fetch("DISCOGS_SECRET")
    $discogs_token = ENV.fetch("DISCOGS_TOKEN")
    @discogs_url = "https://api.discogs.com/database/search?type=release&format=vinyl&catno=#{$catnum}&key=#{$discogs_key}&secret=#{$discogs_secret}"
    raw_discogs_data = HTTP.get(@discogs_url)
    parsed_discogs_data = JSON.parse(raw_discogs_data)
    $results_array = parsed_discogs_data.fetch("results")
    first_result_hash = $results_array.at(0)
    pagination_hash = parsed_discogs_data.fetch("pagination")

    if first_result_hash.nil?
      render(template: "search/not_found")
    else 
      #calculating number of pressings
      @num_pressings = pagination_hash.fetch("items").to_i
      #determining whether there are multiple masters, pressings, or if it's a single pressing
      if @num_pressings > 1
         @master_ids = []
         $results_array.each do |item|
          master_id = item.fetch("master_id").to_i
          @master_ids << master_id
         end 
         @num_masters = @master_ids.uniq.length
        if @num_masters > 1
          render(template: "search/multiple_releases")
        else 
          render(template: "search/multiple_pressings")
        end 
      else 
        render(template: "search/single_pressing")
      end 
    
    end 

  end 

end 
