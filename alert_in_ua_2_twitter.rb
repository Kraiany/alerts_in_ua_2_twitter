require './alert_in_ua_2_twitter/version'
require './alert_in_ua_2_twitter/db'
require './alert_in_ua_2_twitter/alert_retriever'
require './alert_in_ua_2_twitter/translation'

API_TOKEN = ENV['ALERTS_IN_UA_TOKEN']
TWITTER_CONSUMER_KEY = 'your_consumer_key'
TWITTER_CONSUMER_SECRET = 'your_consumer_secret'
TWITTER_ACCESS_TOKEN = 'your_access_token'
TWITTER_ACCESS_SECRET = 'your_access_secret'
SNITCH_URL = ENV['SNITCH_URL']

class AlertInUa2Twitter
  def initialize(lang = :ja)
    MiniI18n.locale = lang
  end

  def alert
    started_alerts, active_alerts, terminated_alerts = AlertInUa2Twitter::AlertRetriever.new.get

    format_and_notify([started_alerts, active_alerts].flatten, :started) if started_alerts.any?
    format_and_notify(terminated_alerts, :finished) if terminated_alerts.any?
  end

private

  def format_and_notify(alerts, kind)
    m = []

    alerts.each do |a|
      m << MiniI18n.t(a.location_title)
    end

    message = [
      MiniI18n.t(:started),
      m.sort.join(MiniI18n.t(:comma)),
      MiniI18n.t(:period)
    ].join

    tweet_message(message)
  end

  def tweet_message(message)
    puts "Tweeting #{message}"
  end
end

