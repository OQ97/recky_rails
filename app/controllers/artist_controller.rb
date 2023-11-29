class ArtistController < ApplicationController

  def search
    #Getting search text
    @text = params.fetch("searchartist")
    @redirect_text = @text.gsub(" ", "+")
  
    #Retreiving data from Discogs
    $discogs_key = ENV.fetch("DISCOGS_KEY")
    $discogs_secret = ENV.fetch("DISCOGS_SECRET")
    $discogs_token = ENV.fetch("DISCOGS_TOKEN")
    @discogs_url = "https://api.discogs.com/database/search?type=artist&query=#{@text.downcase}&key=#{$discogs_key}&secret=#{$discogs_secret}&per_page=100"
    raw_discogs_data = HTTP.get(@discogs_url)
    parsed_discogs_data = JSON.parse(raw_discogs_data)
    @unfiltered_results = parsed_discogs_data.fetch("results")
    $query_total_results = parsed_discogs_data.fetch("pagination").fetch("items").to_i
    $results_array = @unfiltered_results

    @real_count = $results_array.count { |hash| hash["title"].casecmp("#{@text}").zero?}
        
    #render(template: "general/test")


    if @real_count == 0
      redirect_to "/notfound"
    elsif @real_count == 1
      redirect_to "/search/artist/#{@redirect_text}"
    elsif @real_count > 1
      redirect_to "/search/findartist/#{@redirect_text}"
    else 
      redirect_to "/notfound"
    end

  end 
    
  def find
    @artist_query = params.fetch("artist_query")
    @artist_query = @artist_query.gsub("+", " ")

    @artist_array = $results_array.select { |hash| hash["title"].casecmp("#{@artist_query}").zero?}
    
    render(template: "artist/find")
  end

  def artist
    @artist_query = params.fetch("artist_query")
    @artist_query = @artist_query.gsub("+", " ")

    $discogs_key = ENV.fetch("DISCOGS_KEY")
    $discogs_secret = ENV.fetch("DISCOGS_SECRET")
    $discogs_token = ENV.fetch("DISCOGS_TOKEN")
    @discogs_url = "https://api.discogs.com/database/search?type=release&format=vinyl&artist='#{@artist_query}'&key=#{$discogs_key}&secret=#{$discogs_secret}&per_page=100"
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
      a_hash["master_id"] != 0  && a_hash.key?("year") 
    end
    
    
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

    master_counts = $results_array.group_by { |h| h["master_id"] }.transform_values(&:count)
    @masters_list = @masters_list.sort_by { |h| -master_counts.fetch(h["master_id"], 0) }

    render(template: "artist/found")
  end 


  #End for controller
  end 
  