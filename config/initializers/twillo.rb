

ENV['TWILIO_SID'] or raise "please export env var TWILIO_SID"
ENV['TWILIO_TOKEN'] or raise "please export env var TWILIO_TOKEN"

Twilio::Config.setup :account_sid => ENV['TWILIO_SID'],  :account_token => ENV['TWILIO_TOKEN']

