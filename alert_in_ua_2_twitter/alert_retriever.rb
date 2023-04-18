require 'net/http'
require 'json'
require 'sequel'
require 'state_machines'

class AlertInUa2Twitter
  class Alert < Sequel::Model
    state_machine :state, initial: :active do
      event :activate do
        transition any => :active
      end

      event :terminate do
        transition :active => :terminated
      end
    end

    def to_s
      "#<Alert id: #{id}, started_at: #{started_at}, finished_at: #{finished_at}, state: #{state}, location: #{location_title}>"
    end
  end

  Alert.unrestrict_primary_key

  class AlertRetriever
    def get
      alerts = ENV['DEBUG'] ? fetch_mocked_alerts : fetch_alerts
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

      started_alert_ids = started_alerts.map{ |alert| alert['id'] }
      active_alerts = Alert.where(state: 'active').exclude(id: started_alert_ids).to_a

      [started_alerts, active_alerts, terminated_alerts]
    end

    def fetch_alerts
      uri = URI("https://api.alerts.in.ua/v1/alerts/active.json")
      req = Net::HTTP::Get.new(uri)
      req['Authorization'] = "Bearer #{API_TOKEN}"
      req['User-Agent'] = "AlertInUa2Twitter #{VERSION}"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
      if response.code == '200'
        JSON.parse(response.body)["alerts"]
      else
        raise "No alerts: #{response.body}"
      end
    end

    def fetch_mocked_alerts
      file = File.read("./support/mock_response.json")
      JSON.parse(file)["alerts"]
    end
  end
end
