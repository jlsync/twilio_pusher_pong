class RootController < ApplicationController

  respond_to :voice, :html

  def index
  end

  def  twilio
    if params[:Digits]
      # do something with  pusher
      d = params[:Digit]
      from = params[:From]
      
      render 'digit'
      return
    else
      render 'twilio'
    end
  end


end
