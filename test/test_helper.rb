require 'minitest/autorun'
require 'vcr'
require 'webmock/minitest'
require_relative '../alert_in_ua_2_twitter'

VCR.configure do |config|
  config.cassette_library_dir = 'support/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.default_cassette_options = { record: :new_episodes }
  %w[
    ALERTS_IN_UA_TOKEN
    TWITTER_CONSUMER_KEY
    TWITTER_CONSUMER_SECRET
    TWITTER_ACCESS_TOKEN
    TWITTER_ACCESS_SECRET
    SNITCH_URL
  ].each do |key|
    config.filter_sensitive_data(["<", key, ">"].join) { ENV[key] }
  end

  config.before_record do |interaction|
    interaction.response.body.force_encoding('UTF-8')
  end
end
