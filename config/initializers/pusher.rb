
Pusher.app_id = ENV['PUSHER_APP_ID'] or raise 'Please set env var PUSHER_APP_ID'
Pusher.key =  ENV['PUSHER_KEY'] or raise "Please set env var PUSHER_KEY"
Pusher.secret =  ENV['PUSHER_SECRET'] or raise "Please set env var PUSHER_SECRET"

