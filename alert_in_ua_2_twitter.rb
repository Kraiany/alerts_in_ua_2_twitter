require './alert_in_ua_2_twitter/version'
require './alert_in_ua_2_twitter/db'
require './alert_in_ua_2_twitter/alert_retriever'

API_TOKEN = ENV['ALERTS_IN_UA_TOKEN']
TWITTER_CONSUMER_KEY = 'your_consumer_key'
TWITTER_CONSUMER_SECRET = 'your_consumer_secret'
TWITTER_ACCESS_TOKEN = 'your_access_token'
TWITTER_ACCESS_SECRET = 'your_access_secret'
SNITCH_URL = ENV['SNITCH_URL']

class AlertInUa2Twitter
  attr_reader :lang

  def initialize
    @lang = :ja
  end

  def alert
    started_alerts, active_alerts, terminated_alerts = fetch_active_alerts

    puts "Started: #{started_alerts.join}"
    puts "Active: #{active_alerts.join}"
    puts "Terminated: #{terminated_alerts.join}"
    # message = format_message(lang, active_alerts)
    # tweet_message(message)
  end

private

  def fetch_active_alerts
    AlertInUa2Twitter::AlertRetriever.new.get
  end

  def format_message(lang, alerts)
    "Some message goes here...: #{alerts.join}"
  end

  def tweet_message(message)
    puts "Tweeting #{message}"
  end
end

