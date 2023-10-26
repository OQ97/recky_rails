Rails.application.routes.draw do
  #General directories 
  get("/", controller:"general", action: "homepage")
  get("/notfound", controller:"general", action: "notfound")



  #Catno
  get("/search/catno", controller: "catno", action: "search")
  get("search/catno/multreleases/:catno", controller: "catno", action: "multreleases")
  get("search/catno/findpressing/:masterid/:catno", controller: "catno", action: "findpressing")
  get("search/catno/pressing/:recordid", controller: "catno", action: "pressing")


end
