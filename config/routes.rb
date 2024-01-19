Rails.application.routes.draw do
  #General directories 
  
  get("/", controller:"general", action: "homepage")
  get("/notfound", controller:"general", action: "notfound")
  get("/search/", controller: "catno", action: "search")
  get("search/multreleases/:searchitem", controller: "general", action: "multreleases")
  get("search/findpressing/:searchitem", controller: "general", action: "findpressing")
  get("search/pressing/:searchitem", controller: "general", action: "pressing")
  get("/search/finding/:user_selection", controller: "general", action: "finding")
  get("/search/explore/:searchitem", controller: "general", action: "explore")
  get("/about", controller: "general", action: "about")
  get("sandbox", controller: "general", action: "sandbox")
  get("sandbox/:code", controller: "general", action: "code")

  get("/error", controller: "errors", action:"error")

  #Catno
  get("/search/catno", controller: "catno", action: "search")
  get("/search/catno/:artist_search", controller: "catno", action: "search")
  get("search/catno/multreleases/:searchitem", controller: "general", action: "multreleases")
  get("search/catno/findpressing/:searchitem", controller: "general", action: "findpressing")
  get("search/catno/pressing/:searchitem", controller: "general", action: "pressing")
  get("/search/catno/finding/:user_selection", controller: "general", action: "finding")
  get("/search/catno/explore/:searchitem", controller: "general", action: "explore")

  #Record name
  get("/search/name", controller: "name", action: "search")
  get("search/name/multreleases/:searchitem", controller: "general", action: "multreleases")
  get("search/name/findpressing/:searchitem", controller: "general", action: "findpressing")
  get("search/name/pressing/:searchitem", controller: "general", action: "pressing")

  #Artist
  get("/search/artist", controller:"artist", action: "search")
  get("/search/findartist/:artist_query", controller:"artist", action: "find")
  get("/search/artist/:artist_query", controller:"artist", action: "artist")

  #Barcode
  get("/search/barcode", controller:"barcode", action: "search")
  get("/search/barcode/:searchbarcode", controller:"barcode", action: "search")

end
