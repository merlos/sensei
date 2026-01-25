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

    #
    # Summary Endpoints (Daily, Weekly, Monthly)
    #

    # == Daily Summary Tests ==

    test "daily summary should return aggregated data by day" do
        get "/sensor_data/test_sensor/daily", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        # We have 3 data points on 3 different days
        assert_equal 3, body.length
        
        # Check structure of first result
        first = body.first
        assert first.key?("period_start")
        assert first.key?("period_end")
        assert first.key?("average")
        assert first.key?("min")
        assert first.key?("max")
        assert first.key?("count")
    end

    test "daily summary should calculate correct statistics" do
        # Create more data points on the same day for testing aggregation
        Sensor.find_or_create_by!(code: "multi_sensor", name: "Multi", units: "C", value_type: "float")
        SensorDatum.create!(sensor_code: "multi_sensor", value: "10.0", created_at: Time.utc(2025, 8, 15, 8, 0, 0))
        SensorDatum.create!(sensor_code: "multi_sensor", value: "20.0", created_at: Time.utc(2025, 8, 15, 12, 0, 0))
        SensorDatum.create!(sensor_code: "multi_sensor", value: "30.0", created_at: Time.utc(2025, 8, 15, 18, 0, 0))

        get "/sensor_data/multi_sensor/daily", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)

        assert_equal 1, body.length
        day_summary = body.first
        
        assert_equal 20.0, day_summary["average"]
        assert_equal 10.0, day_summary["min"]
        assert_equal 30.0, day_summary["max"]
        assert_equal 3, day_summary["count"]
    end

    test "daily summary should filter with after parameter" do
        get "/sensor_data/test_sensor/daily?after=2025-08-02T00:00:00Z", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        # Should only include Aug 2 and Aug 3
        assert_equal 2, body.length
    end

    test "daily summary should filter with before parameter" do
        get "/sensor_data/test_sensor/daily?before=2025-08-02T23:59:59Z", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        # Should only include Aug 1 and Aug 2
        assert_equal 2, body.length
    end

    test "daily summary should filter with both after and before parameters" do
        get "/sensor_data/test_sensor/daily?after=2025-08-02T00:00:00Z&before=2025-08-02T23:59:59Z", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        # Should only include Aug 2
        assert_equal 1, body.length
    end

    test "daily summary should paginate results" do
        get "/sensor_data/test_sensor/daily?page=1&per=2", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        assert_equal 2, body.length
    end

    # == Weekly Summary Tests ==

    test "weekly summary should return aggregated data by week" do
        # Create data spanning multiple weeks
        Sensor.find_or_create_by!(code: "weekly_sensor", name: "Weekly", units: "C", value_type: "float")
        
        # Week 1 (first week of Aug 2025)
        SensorDatum.create!(sensor_code: "weekly_sensor", value: "15.0", created_at: Time.utc(2025, 8, 4)) # Monday
        SensorDatum.create!(sensor_code: "weekly_sensor", value: "25.0", created_at: Time.utc(2025, 8, 6)) # Wednesday
        
        # Week 2 
        SensorDatum.create!(sensor_code: "weekly_sensor", value: "30.0", created_at: Time.utc(2025, 8, 11)) # Monday
        SensorDatum.create!(sensor_code: "weekly_sensor", value: "40.0", created_at: Time.utc(2025, 8, 13)) # Wednesday

        get "/sensor_data/weekly_sensor/weekly", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        assert_equal 2, body.length
        
        # Most recent week first (descending order)
        week2 = body.first
        assert_equal 35.0, week2["average"]
        assert_equal 30.0, week2["min"]
        assert_equal 40.0, week2["max"]
        assert_equal 2, week2["count"]
    end

    test "weekly summary should handle partial weeks" do
        # Data only for part of a week
        Sensor.find_or_create_by!(code: "partial_week", name: "Partial", units: "C", value_type: "float")
        SensorDatum.create!(sensor_code: "partial_week", value: "20.0", created_at: Time.utc(2025, 8, 4)) # Monday only
        
        get "/sensor_data/partial_week/weekly", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        assert_equal 1, body.length
        assert_equal 1, body.first["count"]
        assert_equal 20.0, body.first["average"]
    end

    # == Monthly Summary Tests ==

    test "monthly summary should return aggregated data by month" do
        # Create data spanning multiple months
        Sensor.find_or_create_by!(code: "monthly_sensor", name: "Monthly", units: "C", value_type: "float")
        
        # August 2025
        SensorDatum.create!(sensor_code: "monthly_sensor", value: "20.0", created_at: Time.utc(2025, 8, 1))
        SensorDatum.create!(sensor_code: "monthly_sensor", value: "30.0", created_at: Time.utc(2025, 8, 15))
        
        # September 2025
        SensorDatum.create!(sensor_code: "monthly_sensor", value: "15.0", created_at: Time.utc(2025, 9, 1))
        SensorDatum.create!(sensor_code: "monthly_sensor", value: "25.0", created_at: Time.utc(2025, 9, 15))

        get "/sensor_data/monthly_sensor/monthly", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        assert_equal 2, body.length
        
        # Most recent month first
        sept = body.first
        assert_equal 20.0, sept["average"]
        assert_equal 15.0, sept["min"]
        assert_equal 25.0, sept["max"]
        assert_equal 2, sept["count"]
    end

    test "monthly summary should filter with date range" do
        Sensor.find_or_create_by!(code: "month_filter", name: "MonthFilter", units: "C", value_type: "float")
        SensorDatum.create!(sensor_code: "month_filter", value: "10.0", created_at: Time.utc(2025, 7, 15))
        SensorDatum.create!(sensor_code: "month_filter", value: "20.0", created_at: Time.utc(2025, 8, 15))
        SensorDatum.create!(sensor_code: "month_filter", value: "30.0", created_at: Time.utc(2025, 9, 15))

        get "/sensor_data/month_filter/monthly?after=2025-08-01T00:00:00Z&before=2025-08-31T23:59:59Z", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        # Should only include August
        assert_equal 1, body.length
        assert_equal 20.0, body.first["average"]
    end

    test "monthly summary should handle partial month from after filter" do
        # If after is mid-month, only data from that point should be included
        Sensor.find_or_create_by!(code: "partial_month", name: "PartialMonth", units: "C", value_type: "float")
        SensorDatum.create!(sensor_code: "partial_month", value: "10.0", created_at: Time.utc(2025, 8, 5))
        SensorDatum.create!(sensor_code: "partial_month", value: "20.0", created_at: Time.utc(2025, 8, 15))
        SensorDatum.create!(sensor_code: "partial_month", value: "30.0", created_at: Time.utc(2025, 8, 25))

        get "/sensor_data/partial_month/monthly?after=2025-08-10T00:00:00Z", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        # Should only include the 2 data points after Aug 10
        assert_equal 1, body.length
        assert_equal 25.0, body.first["average"]  # (20 + 30) / 2
        assert_equal 2, body.first["count"]
    end

    # == Error Handling Tests ==

    test "summary should reject request without authorization" do
        get "/sensor_data/test_sensor/daily"
        assert_response :unauthorized
    end

    test "summary should return empty array for non-existent sensor" do
        get "/sensor_data/nonexistent_sensor/daily", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        assert_equal [], body
    end

    # == Response Format Tests ==

    test "summary response should include proper period boundaries" do
        Sensor.find_or_create_by!(code: "boundary_test", name: "Boundary", units: "C", value_type: "float")
        SensorDatum.create!(sensor_code: "boundary_test", value: "20.0", created_at: Time.utc(2025, 8, 15, 12, 30, 0))

        get "/sensor_data/boundary_test/daily", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        day = body.first
        # Period start should be beginning of day
        assert_match(/2025-08-15T00:00:00/, day["period_start"])
        # Period end should be end of day
        assert_match(/2025-08-15T23:59:59/, day["period_end"])
    end

    test "summary should order results by period descending" do
        get "/sensor_data/test_sensor/daily", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        # Most recent first
        periods = body.map { |b| b["period_start"] }
        assert_equal periods.sort.reverse, periods
    end

    #
    # Last Period Endpoints - Raw Data Points (day, week, month, year, all)
    #

    # == Last Day Tests ==

    test "last day should return raw data points from last 24 hours" do
        # Create data points within the last 24 hours
        Sensor.find_or_create_by!(code: "last_day_sensor", name: "Last Day", units: "C", value_type: "float")
        now = Time.current
        SensorDatum.create!(sensor_code: "last_day_sensor", value: "20.0", created_at: now - 1.hour)
        SensorDatum.create!(sensor_code: "last_day_sensor", value: "21.0", created_at: now - 12.hours)
        SensorDatum.create!(sensor_code: "last_day_sensor", value: "22.0", created_at: now - 23.hours)
        # This one should be excluded (older than 24h)
        SensorDatum.create!(sensor_code: "last_day_sensor", value: "19.0", created_at: now - 25.hours)

        get "/sensor_data/last_day_sensor/last/day", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        # Should return 3 raw data points (not the one older than 24h)
        assert_equal 3, body.length
        # Should have raw data structure (not summary)
        assert body.first.key?("value")
        assert body.first.key?("sensor_code")
        assert_equal "last_day_sensor", body.first["sensor_code"]
    end

    test "last day should return data ordered by created_at descending" do
        Sensor.find_or_create_by!(code: "last_day_order", name: "Order Test", units: "C", value_type: "float")
        now = Time.current
        SensorDatum.create!(sensor_code: "last_day_order", value: "20.0", created_at: now - 5.hours)
        SensorDatum.create!(sensor_code: "last_day_order", value: "21.0", created_at: now - 1.hour)
        SensorDatum.create!(sensor_code: "last_day_order", value: "22.0", created_at: now - 10.hours)

        get "/sensor_data/last_day_order/last/day", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        # Most recent first
        timestamps = body.map { |b| Time.parse(b["created_at"]) }
        assert_equal timestamps.sort.reverse, timestamps
    end

    # == Last Week Tests ==

    test "last week should return raw data points from last 7 days" do
        Sensor.find_or_create_by!(code: "last_week_sensor", name: "Last Week", units: "C", value_type: "float")
        now = Time.current
        SensorDatum.create!(sensor_code: "last_week_sensor", value: "20.0", created_at: now - 1.day)
        SensorDatum.create!(sensor_code: "last_week_sensor", value: "21.0", created_at: now - 3.days)
        SensorDatum.create!(sensor_code: "last_week_sensor", value: "22.0", created_at: now - 6.days)
        # This one should be excluded (older than 7 days)
        SensorDatum.create!(sensor_code: "last_week_sensor", value: "19.0", created_at: now - 8.days)

        get "/sensor_data/last_week_sensor/last/week", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        # Should return 3 raw data points
        assert_equal 3, body.length
        # Should have raw data structure
        assert body.first.key?("value")
    end

    test "last week should support pagination" do
        Sensor.find_or_create_by!(code: "last_week_page", name: "Page Test", units: "C", value_type: "float")
        now = Time.current
        5.times { |i| SensorDatum.create!(sensor_code: "last_week_page", value: "#{20 + i}", created_at: now - i.days) }

        get "/sensor_data/last_week_page/last/week?page=1&per=2", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        assert_equal 2, body.length
    end

    # == Last Month Tests (now returns raw data) ==

    test "last month should return raw data points for last 30 days" do
        Sensor.find_or_create_by!(code: "last_month_sensor", name: "Last Month", units: "C", value_type: "float")
        now = Time.current
        SensorDatum.create!(sensor_code: "last_month_sensor", value: "20.0", created_at: now - 5.days)
        SensorDatum.create!(sensor_code: "last_month_sensor", value: "21.0", created_at: now - 5.days + 6.hours)
        SensorDatum.create!(sensor_code: "last_month_sensor", value: "25.0", created_at: now - 10.days)
        SensorDatum.create!(sensor_code: "last_month_sensor", value: "22.0", created_at: now - 20.days)
        # This one should be excluded (older than 30 days)
        SensorDatum.create!(sensor_code: "last_month_sensor", value: "19.0", created_at: now - 35.days)

        get "/sensor_data/last_month_sensor/last/month", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        # Should return raw data points (not summaries)
        assert body.first.key?("value")
        assert body.first.key?("sensor_code")
        
        # Should have 4 data points (not the one older than 30 days)
        assert_equal 4, body.length
    end

    # == Last Year Tests (now returns raw data) ==

    test "last year should return raw data points for last 365 days" do
        Sensor.find_or_create_by!(code: "last_year_sensor", name: "Last Year", units: "C", value_type: "float")
        now = Time.current
        SensorDatum.create!(sensor_code: "last_year_sensor", value: "20.0", created_at: now - 30.days)
        SensorDatum.create!(sensor_code: "last_year_sensor", value: "21.0", created_at: now - 100.days)
        SensorDatum.create!(sensor_code: "last_year_sensor", value: "22.0", created_at: now - 300.days)
        # This one should be excluded (older than 365 days)
        SensorDatum.create!(sensor_code: "last_year_sensor", value: "19.0", created_at: now - 400.days)

        get "/sensor_data/last_year_sensor/last/year", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        # Should return raw data points
        assert body.first.key?("value")
        
        # Should have 3 data points
        assert_equal 3, body.length
    end

    # == Last All Tests (now returns raw data) ==

    test "last all should return raw data points for all historical data" do
        Sensor.find_or_create_by!(code: "last_all_sensor", name: "Last All", units: "C", value_type: "float")
        now = Time.current
        SensorDatum.create!(sensor_code: "last_all_sensor", value: "20.0", created_at: now - 30.days)
        SensorDatum.create!(sensor_code: "last_all_sensor", value: "21.0", created_at: now - 400.days)
        SensorDatum.create!(sensor_code: "last_all_sensor", value: "22.0", created_at: now - 800.days)

        get "/sensor_data/last_all_sensor/last/all", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        # Should return raw data points
        assert body.first.key?("value")
        
        # Should include all 3 data points
        assert_equal 3, body.length
    end

    test "last all should support pagination" do
        Sensor.find_or_create_by!(code: "last_all_page", name: "All Page", units: "C", value_type: "float")
        now = Time.current
        10.times { |i| SensorDatum.create!(sensor_code: "last_all_page", value: "#{20 + i}", created_at: now - (i * 30).days) }

        get "/sensor_data/last_all_page/last/all?page=1&per=5", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        assert_equal 5, body.length
    end

    # == Last Period Error Handling Tests ==

    test "last period should reject request without authorization" do
        get "/sensor_data/test_sensor/last/day"
        assert_response :unauthorized
    end

    test "last period should return empty array for non-existent sensor" do
        get "/sensor_data/nonexistent_sensor/last/day", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        assert_equal [], body
    end

    test "last period should return error for invalid period" do
        get "/sensor_data/test_sensor/last/invalid", headers: @headers
        assert_response :not_found  # Rails will return 404 for unmatched route
    end

    test "last period should handle sensor with no recent data" do
        # test_sensor has data from August 2025, which is old
        get "/sensor_data/test_sensor/last/day", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        # Should return empty array since no data in last 24h
        assert_equal [], body
    end

    #
    # Daily-Last Period Endpoints - Daily Summaries (day, week, month, year, all)
    #

    # == Daily-Last Day Tests ==

    test "daily-last day should return daily summaries for last 24 hours" do
        Sensor.find_or_create_by!(code: "daily_last_day", name: "Daily Last Day", units: "C", value_type: "float")
        now = Time.current
        # Create multiple readings on the same day (within last 24h)
        SensorDatum.create!(sensor_code: "daily_last_day", value: "10.0", created_at: now - 1.hour)
        SensorDatum.create!(sensor_code: "daily_last_day", value: "20.0", created_at: now - 2.hours)
        SensorDatum.create!(sensor_code: "daily_last_day", value: "30.0", created_at: now - 3.hours)
        # This one should be excluded (older than 24h)
        SensorDatum.create!(sensor_code: "daily_last_day", value: "50.0", created_at: now - 25.hours)

        get "/sensor_data/daily_last_day/daily-last/day", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        # Should return daily summaries (not raw data)
        assert body.first.key?("period_start")
        assert body.first.key?("period_end")
        assert body.first.key?("average")
        assert body.first.key?("min")
        assert body.first.key?("max")
        assert body.first.key?("count")
        
        # Should have correct statistics for the 3 data points
        day_summary = body.first
        assert_equal 20.0, day_summary["average"]
        assert_equal 10.0, day_summary["min"]
        assert_equal 30.0, day_summary["max"]
        assert_equal 3, day_summary["count"]
    end

    # == Daily-Last Week Tests ==

    test "daily-last week should return daily summaries for last 7 days" do
        Sensor.find_or_create_by!(code: "daily_last_week", name: "Daily Last Week", units: "C", value_type: "float")
        now = Time.current
        # Create data points on different days
        SensorDatum.create!(sensor_code: "daily_last_week", value: "20.0", created_at: now - 1.day)
        SensorDatum.create!(sensor_code: "daily_last_week", value: "21.0", created_at: now - 3.days)
        SensorDatum.create!(sensor_code: "daily_last_week", value: "22.0", created_at: now - 5.days)
        # This one should be excluded (older than 7 days)
        SensorDatum.create!(sensor_code: "daily_last_week", value: "19.0", created_at: now - 10.days)

        get "/sensor_data/daily_last_week/daily-last/week", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        # Should return daily summaries
        assert body.first.key?("period_start")
        assert body.first.key?("average")
        
        # Should have 3 day summaries
        assert_equal 3, body.length
    end

    # == Daily-Last Month Tests ==

    test "daily-last month should return daily summaries for last 30 days" do
        Sensor.find_or_create_by!(code: "daily_last_month", name: "Daily Last Month", units: "C", value_type: "float")
        now = Time.current
        # Create data points across multiple days
        SensorDatum.create!(sensor_code: "daily_last_month", value: "20.0", created_at: now - 5.days)
        SensorDatum.create!(sensor_code: "daily_last_month", value: "21.0", created_at: now - 5.days + 6.hours)
        SensorDatum.create!(sensor_code: "daily_last_month", value: "25.0", created_at: now - 10.days)
        SensorDatum.create!(sensor_code: "daily_last_month", value: "22.0", created_at: now - 20.days)
        # This one should be excluded (older than 30 days)
        SensorDatum.create!(sensor_code: "daily_last_month", value: "19.0", created_at: now - 35.days)

        get "/sensor_data/daily_last_month/daily-last/month", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        # Should return daily summaries
        assert body.first.key?("period_start")
        assert body.first.key?("average")
        
        # Should have 3 day summaries (2 readings on day 5 ago count as 1 day)
        assert_equal 3, body.length
    end

    test "daily-last month should calculate correct statistics" do
        Sensor.find_or_create_by!(code: "daily_last_month_stats", name: "Stats Test", units: "C", value_type: "float")
        now = Time.current
        # Create multiple readings on the same day
        day_5_ago = (now - 5.days).beginning_of_day + 12.hours
        SensorDatum.create!(sensor_code: "daily_last_month_stats", value: "10.0", created_at: day_5_ago)
        SensorDatum.create!(sensor_code: "daily_last_month_stats", value: "20.0", created_at: day_5_ago + 1.hour)
        SensorDatum.create!(sensor_code: "daily_last_month_stats", value: "30.0", created_at: day_5_ago + 2.hours)

        get "/sensor_data/daily_last_month_stats/daily-last/month", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        day_summary = body.first
        assert_equal 20.0, day_summary["average"]
        assert_equal 10.0, day_summary["min"]
        assert_equal 30.0, day_summary["max"]
        assert_equal 3, day_summary["count"]
    end

    # == Daily-Last Year Tests ==

    test "daily-last year should return daily summaries for last 365 days" do
        Sensor.find_or_create_by!(code: "daily_last_year", name: "Daily Last Year", units: "C", value_type: "float")
        now = Time.current
        SensorDatum.create!(sensor_code: "daily_last_year", value: "20.0", created_at: now - 30.days)
        SensorDatum.create!(sensor_code: "daily_last_year", value: "21.0", created_at: now - 100.days)
        SensorDatum.create!(sensor_code: "daily_last_year", value: "22.0", created_at: now - 300.days)
        # This one should be excluded (older than 365 days)
        SensorDatum.create!(sensor_code: "daily_last_year", value: "19.0", created_at: now - 400.days)

        get "/sensor_data/daily_last_year/daily-last/year", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        # Should return daily summaries
        assert body.first.key?("period_start")
        assert body.first.key?("average")
        
        # Should have 3 day summaries
        assert_equal 3, body.length
    end

    # == Daily-Last All Tests ==

    test "daily-last all should return daily summaries for all historical data" do
        Sensor.find_or_create_by!(code: "daily_last_all", name: "Daily Last All", units: "C", value_type: "float")
        now = Time.current
        SensorDatum.create!(sensor_code: "daily_last_all", value: "20.0", created_at: now - 30.days)
        SensorDatum.create!(sensor_code: "daily_last_all", value: "21.0", created_at: now - 400.days)
        SensorDatum.create!(sensor_code: "daily_last_all", value: "22.0", created_at: now - 800.days)

        get "/sensor_data/daily_last_all/daily-last/all", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        # Should return daily summaries
        assert body.first.key?("period_start")
        
        # Should include all 3 days
        assert_equal 3, body.length
    end

    test "daily-last all should support pagination" do
        Sensor.find_or_create_by!(code: "daily_last_all_page", name: "All Page", units: "C", value_type: "float")
        now = Time.current
        10.times { |i| SensorDatum.create!(sensor_code: "daily_last_all_page", value: "#{20 + i}", created_at: now - (i * 30).days) }

        get "/sensor_data/daily_last_all_page/daily-last/all?page=1&per=5", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        
        assert_equal 5, body.length
    end

    # == Daily-Last Error Handling Tests ==

    test "daily-last period should reject request without authorization" do
        get "/sensor_data/test_sensor/daily-last/day"
        assert_response :unauthorized
    end

    test "daily-last period should return empty array for non-existent sensor" do
        get "/sensor_data/nonexistent_sensor/daily-last/day", headers: @headers
        assert_response :success
        body = JSON.parse(response.body)
        assert_equal [], body
    end

    test "daily-last period should return error for invalid period" do
        get "/sensor_data/test_sensor/daily-last/invalid", headers: @headers
        assert_response :not_found  # Rails will return 404 for unmatched route
    end
end
