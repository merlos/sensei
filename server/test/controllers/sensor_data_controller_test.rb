require "test_helper"

class SensorDataControllerTest < ActionDispatch::IntegrationTest
    setup do
        @token = Rails.application.credentials.dig(:sensor_api, :bearer_token) || "my-secret-token-123"
        @headers = {
            "Authorization" => "Bearer #{@token}",
            "Content-Type" => "application/json"
        }

        Sensor.create!(code: "test_sensor", 
            name: "Test Sensor", 
            units: "C", 
            value_type: "float")

        3.times do |i|
            SensorDatum.create!(
                sensor_code: "test_sensor",
                value: "#{20 + i}",
                created_at: Time.utc(2025, 8, 1 + i))
        end
    end

    #    
    # Create 
    #
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

    #
    # Index 
    #

    test "should get data for a specific sensor_code" do
        get "/sensor_data/test_sensor", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        assert_equal 3, body.length
    end

    test "should get filtered data with after and before" do
        get "/sensor_data/test_sensor?after=2025-08-02T00:00:00Z&before=2025-08-03T23:59:59Z", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        assert_equal 2, body.length
    end

    test "should paginate data" do
        get "/sensor_data/test_sensor?page=1&per=2", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        assert_equal 2, body.length
    end

    test "should return 400 if sensor_code is missing" do
        get "/sensor_data/", headers: @headers
        assert_response :not_found
    end
end
