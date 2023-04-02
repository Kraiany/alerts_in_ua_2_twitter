require 'net/http'
require 'json'
require 'twitter'
require 'sequel'
require 'state_machines'
require './translations.rb'

API_TOKEN = ENV['ALERTS_IN_UA_TOKEN']
TWITTER_CONSUMER_KEY = 'your_consumer_key'
TWITTER_CONSUMER_SECRET = 'your_consumer_secret'
TWITTER_ACCESS_TOKEN = 'your_access_token'
TWITTER_ACCESS_SECRET = 'your_access_secret'

DB = Sequel.sqlite('alerts.db')
DB.create_table?(:alerts) do
  primary_key :id
  String :location_title
  String :location_type
  DateTime :started_at
  DateTime :finished_at
  DateTime :updated_at
  String :alert_type
  String :location_uid
  String :location_oblast
  String :location_raion
  String :notes
  TrueClass :calculated
  String :state
end

class Alert < Sequel::Model
  state_machine :state, initial: :active do
    event :activate do
      transition any => :active
    end

    event :terminate do
      transition :active => :terminated
    end
  end
end

Alert.unrestrict_primary_key

def fetch_alerts
  uri = URI("https://api.alerts.in.ua/v1/alerts/active.json")
  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{API_TOKEN}"
  req['User-Agent'] = "Ruby Client 1.3.3.7"

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
  response.code == '200' ? JSON.parse(response.body)["alerts"] : nil
end

def send_twitter_notification(alert)
  client = Twitter::REST::Client.new do |config|
    config.consumer_key        = TWITTER_CONSUMER_KEY
    config.consumer_secret     = TWITTER_CONSUMER_SECRET
    config.access_token        = TWITTER_ACCESS_TOKEN
    config.access_token_secret = TWITTER_ACCESS_SECRET
  end

  message = "Alert ID: #{alert.id} | Location: #{alert.location_title} | Type: #{alert.alert_type} | Started: #{alert.started_at} | Finished: #{alert.finished_at}"
  puts "Tweeting message: #{message}"
  client.update(message)
end

def process_alerts
  alerts = fetch_alerts
  return if alerts.nil?
  started_alerts = []
  terminated_alerts = []

  alerts.each do |remote_alert|
    alert_id = remote_alert['id'].to_i
    alert = Alert[alert_id]
    if alert.nil?
      alert = Alert.create(remote_alert)
      started_alerts << alert
    elsif alert.state == 'active' && !remote_alert['finished_at'].nil?
      alert.update(finished_at: remote_alert['finished_at'], updated_at: remote_alert['updated_at'])
      alert.terminate
      alert.save
      terminated_alerts << alert
    end
  end

  remote_ids = alerts.map{ |alert| alert['id'] }
  Alert.where(state: 'active').exclude(id: remote_ids).each do |alert|
    alert.update(finished_at: Time.now, updated_at: Time.now)
    alert.terminate
    alert.save
    terminated_alerts << alert
  end

  [started_alerts, terminated_alerts]
end

def concat_locations(alerts)
  alerts.map(&:location_title).map{ |t| TRANSLATIONS.dig(t.to_sym, :ja) || t }.join(TRANSLATIONS.dig(:comma, :ja))
end

while true
  started_alerts, terminated_alerts = process_alerts

  if started_alerts.any?
    message = "#{concat_locations(started_alerts)}で空襲警報が発令せれました。"
    send_twitter_notification(message)
  end


  if terminated_alerts.any?
    message = "#{concat_locations(terminated_alerts)}で空襲警報が解除されました。"
    send_twitter_notification(message)
  end

  sleep(60)
end

__END__

{"alerts":[{"id":8757,"location_title":"Луганська область","location_type":"oblast","started_at":"2022-04-04T16:45:39.000Z","finished_at":null,"updated_at":"2022-04-08T08:04:26.316Z","alert_type":"air_raid","location_oblast":"Луганська область","location_uid":"16","notes":null,"calculated":null},{"id":28288,"location_title":"Автономна Республіка Крим","location_type":"oblast","started_at":"2022-12-10T22:22:00.000Z","finished_at":null,"updated_at":"2022-12-12T12:20:11.900Z","alert_type":"air_raid","location_oblast":"Автономна Республіка Крим","location_uid":"29","notes":"Згідно інформації з Офіційних карт тривог","calculated":null},{"id":36217,"location_title":"Донецька область","location_type":"oblast","started_at":"2023-04-02T08:32:53.000Z","finished_at":null,"updated_at":"2023-04-02T08:32:55.603Z","alert_type":"air_raid","location_oblast":"Донецька область","location_uid":"28","notes":null,"calculated":null}],"meta":{"last_updated_at":"2023/04/02 08:32:55 +0000","type":"full"},"disclaimer":"If you use python try our official alerts_in_ua PiP package."}
