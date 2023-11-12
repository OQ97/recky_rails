Rails.application.routes.draw do
  #General directories 
  get("/", controller:"general", action: "homepage")
  get("/notfound", controller:"general", action: "notfound")

  #Catno
  get("/search/catno", controller: "catno", action: "search")
  get("search/catno/multreleases/:catno", controller: "catno", action: "multreleases")
  get("search/catno/findpressing/:masterid/:catno", controller: "catno", action: "findpressing")
  get("search/catno/pressing/:recordid", controller: "general", action: "pressing")
  get("/search/catno/finding/:user_selection", controller: "catno", action: "finding")
  get("/search/catno/explore/:masterid/:catno", controller: "catno", action: "explore")

  #Name
  get("/search/name", controller: "name", action: "search")
  get("search/name/multreleases/:text", controller: "name", action: "multreleases")
  get("search/name/findpressing/:masterid/:text", controller: "name", action: "findpressing")
  get("search/name/pressing/:recordid", controller: "general", action: "pressing")

end
