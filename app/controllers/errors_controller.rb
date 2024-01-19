class ErrorsController < ApplicationController
  
  def error
    render(template: "errors/error")
  end 

end 
