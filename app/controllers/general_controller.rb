class GeneralController < ApplicationController

def homepage
  placeholders = ["Unknown Pleasures | FACT10 | 0825646183906", "Purple Rain | RCV1 547450 | 081227880385", "All Things Must Pass | 3565241 | 602435652412", "Madvillainy | STH2065 | 659457206512", "Salad Days | CT-193 | 817949019471", "Schlagenheim | RT0073LP | 191402007312", "Titanic Rising | SP1232 | 098787123210", "In The Aeroplane Over The Sea | MRG136LP | 673855013619", "To Pimp a Butterfly | B0023464-01 | 602547311009", "Bonito Generation | PRC-375 | 644110037510"]

  placeholder_selection = placeholders[rand(0..9)]
  placeholder_items = placeholder_selection.split(" | ")
  @placeholder_name = placeholder_items[0]
  @placeholder_catno = placeholder_items[1]
  @placeholder_barcode = placeholder_items[2]
  
  render(template: "general/homepage")
end 

def notfound
  render(template: "general/notfound")
end 

end 
