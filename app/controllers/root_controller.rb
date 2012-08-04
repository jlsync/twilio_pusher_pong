class RootController < ApplicationController

  respond_to :voice, :html

  def index
  end

  def  twilio
    if params[:Digits]
      # do something with  pusher
      d = params[:Digits]
      from = params[:From]
      Pusher['test_channel'].trigger_async('player', {:from => from, :digit => d})
      render 'digit'
      return
    else
      render 'twilio'
    end
  end

  def  twilio_status
    from = params[:From]
    Pusher['test_channel'].trigger_async('player_leave', {:from => from})
    render :nothing => true, :status => 204
  end

end
