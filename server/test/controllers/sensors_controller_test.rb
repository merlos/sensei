require "test_helper"

class SensorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @token = Rails.application.credentials.dig(:sensor_api, :bearer_token) || "my-secret-token-123"
    @headers = { "Authorization" => "Bearer #{@token}", "Content-Type" => "application/json" }

    Sensor.create!(code: "temp_kitchen", name: "Temperature Kitchen", units: "C", value_type: "float")
    Sensor.create!(code: "humidity_living", name: "Humidity Living", units: "%", value_type: "float")
  end

  test "should get all sensors" do
    get "/sensors", headers: @headers
    assert_response :success
    body = JSON.parse(response.body)
    assert body.is_a?(Array)
    assert body.any? { |s| s["code"] == "temp_kitchen" }
  end
  
end
