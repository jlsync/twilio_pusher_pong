class RootController < ApplicationController

  respond_to :voice, :html

  def index
  end

  def  twilio
    from = params[:From]
    if params[:Digits]
      # do something with  pusher
      d = params[:Digits]
      Pusher['test_channel'].trigger_async('player', {:from => from, :digit => d})
      render 'digit'
      return
    else
      d = "6"
      Pusher['test_channel'].trigger_async('player', {:from => from, :digit => d})
      render 'twilio'
    end
  end

  def  twilio_status
    from = params[:From]
    Pusher['test_channel'].trigger_async('player_leave', {:from => from})
    render :nothing => true, :status => 204
  end

end
