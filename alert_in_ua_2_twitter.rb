class AlertInUa2Twitter
  attr_reader :lang

  def initialize
    @lang = :ja
  end

  def alert
    message = format_message(lang, fetch_active_alerts)
    tweet_message(message)
  end

private

  def fetch_active_alerts
    []
  end

  def format_message(lang, alerts)
    "Some message goes here...: #{alerts.join}"
  end

  def tweet_message(message)
    puts "Tweeting #{message}"
  end
end

