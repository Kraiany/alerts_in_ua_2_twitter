require_relative 'test_helper'

class AlertInUa2TwitterTest < Minitest::Test
  API_TOKEN = 'your_api_token_here'
  VERSION = '1.0.0'

  def test_alert_retrieval
    VCR.use_cassette('alert_in_ua2_twitter') do
      retriever = AlertInUa2Twitter::AlertRetriever.new
      started_alerts, active_alerts, terminated_alerts = retriever.get

      assert started_alerts.count == 1, "Should have one started alert"
      assert active_alerts.empty?, "Active alerts should be empty"
      assert terminated_alerts.empty?, "Terminated alerts should be empty"

      # Same alert
      started_alerts, active_alerts, terminated_alerts = retriever.get

      assert started_alerts.empty?, "Started alerts should be empty"
      assert active_alerts.count == 1, "Should have one active alert"
      assert terminated_alerts.empty?, "Terminated alerts should be empty"

      # with new alert
      started_alerts, active_alerts, terminated_alerts = retriever.get

      assert started_alerts.count == 1, "Should have one started alert"
      assert active_alerts.count == 1, "Should have one active alert"
      assert terminated_alerts.empty?, "Terminated alerts should be empty"

      # with finished alert
      started_alerts, active_alerts, terminated_alerts = retriever.get

      assert started_alerts.empty?, "Started alerts should not be empty"
      assert active_alerts.count == 1, "Should have one active alert"
      assert terminated_alerts.count == 1, "Should have one terminated alert"
    end
  end
end
