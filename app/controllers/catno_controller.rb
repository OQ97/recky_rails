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
  @master_id = params.fetch("masterid")
  @catno = params.fetch("catno")
  render(template: "catno/catno_findpressing")
end 

def pressing
  @record_id = params.fetch("recordid")
  render(template: "catno/catno_pressing")
end 

end 
