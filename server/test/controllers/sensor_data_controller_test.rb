require "test_helper"

class SensorDataControllerTest < ActionDispatch::IntegrationTest
    setup do
        @token = Rails.application.credentials.dig(:sensor_api, :bearer_token) || "my-secret-token-123"
        @headers = {
            "Authorization" => "Bearer #{@token}",
            "Content-Type" => "application/json"
        }
    end

    test "should accept valid sensor data" do
        post "/sensor_data", headers: @headers, params: {
            sensor_code: "temperature_kitchen",
            value: "21.0"
        }.to_json

        assert_response :created
        assert_equal "ok", JSON.parse(response.body)["status"]
    end

    test "should reject request with no token" do
        post "/sensor_data", params: {
            sensor_code: "temp",
            value: "22.0"
        }.to_json, headers: { "Content-Type" => "application/json" }

        assert_response :unauthorized
    end

    test "should reject invalid sensor data (missing fields)" do
        post "/sensor_data", headers: @headers, params: {
            value: "23.0"
        }.to_json
        assert_response :bad_request
    end
end