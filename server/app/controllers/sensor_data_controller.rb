# app/controllers/sensor_data_controller.rb
class SensorDataController < ApplicationController

  def create
    sensor_code = params[:sensor_code]
    value = params[:value]

    unless sensor_code.present? && value.present?
      return render json: { error: 'Missing sensor_code or value' }, status: :bad_request
    end

    # Ensure sensor exists or create metadata placeholder
    sensor = Sensor.find_or_initialize_by(code: sensor_code)
    if sensor.new_record?
      sensor.name = sensor_code.titleize
      sensor.units = ''
      sensor.value_type = 'string'
      sensor.save!
    end

    # Create time-series value
    SensorDatum.create!(sensor_code: sensor_code, value: value)

    render json: { status: 'ok' }, status: :created
  end
 
  # GET /sensor_data/:sensor_code?after=...&before=...&page=1&per=100
  # Eg: GET /sensor_data/temperature_kitchen?after=2025-08-01T00:00:00Z&before=2025-08-06T00:00:00Z&page=1&per=20
  def index
    sensor_code = params[:sensor_code]
    return render json: { error: "sensor_code is required" }, status: :bad_request unless sensor_code

    after_time = SensorDatum.parse_iso8601(params[:after])
    before_time = SensorDatum.parse_iso8601(params[:before])

    data = SensorDatum
      .for_sensor(sensor_code)
      .in_date_range(after_time, before_time)
      .recent_first
      .paginate(page: params[:page], per_page: params[:per], max_per_page: 1000)

    render json: data
  end

  # GET /sensor_data/:sensor_code/daily
  # GET /sensor_data/:sensor_code/weekly  
  # GET /sensor_data/:sensor_code/monthly
  #
  # Returns aggregated summaries of sensor data grouped by day, week, or month.
  #
  # == Description
  # This endpoint provides statistical summaries (average, min, max) of sensor readings
  # aggregated over time periods. Useful for dashboards, charts, and trend analysis.
  #
  # == Parameters
  # - sensor_code (required, in URL): The unique identifier of the sensor
  # - after (optional): ISO8601 timestamp. Only include data points after this time.
  #   Example: after=2025-08-01T00:00:00Z
  # - before (optional): ISO8601 timestamp. Only include data points before this time.
  #   Example: before=2025-08-31T23:59:59Z
  # - page (optional): Page number for pagination. Default: 1
  # - per (optional): Number of periods per page. Default: 50, Max: 100
  #
  # == Response Format
  # Returns a JSON array of period summaries, ordered by period_start descending (most recent first).
  # Each summary object contains:
  # - period_start: ISO8601 timestamp of the period's start
  # - period_end: ISO8601 timestamp of the period's end
  # - average: Mean value of all data points in the period (rounded to 2 decimal places)
  # - min: Minimum value recorded in the period
  # - max: Maximum value recorded in the period
  # - count: Number of data points included in this summary
  #
  # == Period Boundaries
  # - Daily: Midnight to midnight UTC (00:00:00 to 23:59:59)
  # - Weekly: Monday 00:00:00 to Sunday 23:59:59 UTC
  # - Monthly: First day 00:00:00 to last day 23:59:59 UTC
  #
  # == Partial Periods
  # The endpoint handles partial periods gracefully:
  # - Current day/week/month: Uses all available data up to now
  # - Filtered by 'after': If 'after' falls mid-period, only data from 'after' onwards is included
  # - Filtered by 'before': If 'before' falls mid-period, only data up to 'before' is included
  # - Incomplete historical data: If the database lacks data for part of a period,
  #   the summary reflects only the available data points
  #
  # == Examples
  # GET /sensor_data/temperature_kitchen/daily
  # GET /sensor_data/temperature_kitchen/weekly?after=2025-01-01T00:00:00Z
  # GET /sensor_data/temperature_kitchen/monthly?after=2025-01-01T00:00:00Z&before=2025-06-30T23:59:59Z&page=1&per=12
  #
  # == Example Response
  # [
  #   {
  #     "period_start": "2025-08-01T00:00:00Z",
  #     "period_end": "2025-08-01T23:59:59Z",
  #     "average": 22.5,
  #     "min": 18.0,
  #     "max": 27.0,
  #     "count": 144
  #   },
  #   ...
  # ]
  #
  def summary
    sensor_code = params[:sensor_code]
    period_type = params[:period]
    
    return render json: { error: "sensor_code is required" }, status: :bad_request unless sensor_code
    return render json: { error: "Invalid period type" }, status: :bad_request unless SensorDatum.valid_period_type?(period_type)

    after_time = SensorDatum.parse_iso8601(params[:after])
    before_time = SensorDatum.parse_iso8601(params[:before])

    summaries = SensorDatum
      .for_sensor(sensor_code)
      .in_date_range(after_time, before_time)
      .summarize_by_period(period_type)
      .paginate(page: params[:page], per_page: params[:per])

    result = SensorDatum.format_summaries(summaries, period_type)

    render json: result
  end

  # GET /sensor_data/:sensor_code/last/day
  # GET /sensor_data/:sensor_code/last/week
  # GET /sensor_data/:sensor_code/last/month
  # GET /sensor_data/:sensor_code/last/year
  # GET /sensor_data/:sensor_code/last/all
  #
  # Returns all raw sensor data points for a recent time period.
  #
  # == Description
  # This endpoint provides convenient access to recent sensor data as raw data points.
  #
  # - **day**: Last 24 hours
  # - **week**: Last 7 days
  # - **month**: Last 30 days
  # - **year**: Last 365 days
  # - **all**: All historical data
  #
  # == Parameters
  # - sensor_code (required, in URL): The unique identifier of the sensor
  # - page (optional): Page number for pagination. Default: 1
  # - per (optional): Number of items per page. Default: 50, Max: 1000
  #
  # == Response Format
  # [
  #   {
  #     "id": 123,
  #     "sensor_code": "temperature_kitchen",
  #     "value": "22.5",
  #     "created_at": "2025-01-25T14:30:00Z",
  #     "updated_at": "2025-01-25T14:30:00Z"
  #   },
  #   ...
  # ]
  #
  # == Examples
  # GET /sensor_data/temperature_kitchen/last/day
  # GET /sensor_data/temperature_kitchen/last/week?page=1&per=100
  # GET /sensor_data/temperature_kitchen/last/month
  # GET /sensor_data/temperature_kitchen/last/year
  # GET /sensor_data/temperature_kitchen/last/all
  #
  def last_period
    sensor_code = params[:sensor_code]
    period = params[:period]

    return render json: { error: "sensor_code is required" }, status: :bad_request unless sensor_code
    return render json: { error: "Invalid period" }, status: :bad_request unless SensorDatum.valid_last_period?(period)

    data = SensorDatum
      .for_sensor(sensor_code)
      .in_last_period(period)
      .recent_first
      .paginate(page: params[:page], per_page: params[:per], max_per_page: 1000)

    render json: data
  end

  # GET /sensor_data/:sensor_code/daily-last/day
  # GET /sensor_data/:sensor_code/daily-last/week
  # GET /sensor_data/:sensor_code/daily-last/month
  # GET /sensor_data/:sensor_code/daily-last/year
  # GET /sensor_data/:sensor_code/daily-last/all
  #
  # Returns daily aggregated summaries for a recent time period.
  #
  # == Description
  # This endpoint provides daily summaries (avg, min, max, count) of sensor data
  # for the specified time period.
  #
  # - **day**: Last 24 hours (typically 1 day summary)
  # - **week**: Last 7 days (up to 7 day summaries)
  # - **month**: Last 30 days (up to 30 day summaries)
  # - **year**: Last 365 days (up to 365 day summaries)
  # - **all**: All historical data (all days with data)
  #
  # == Parameters
  # - sensor_code (required, in URL): The unique identifier of the sensor
  # - page (optional): Page number for pagination. Default: 1
  # - per (optional): Number of items per page. Default: 50, Max: 100
  #
  # == Response Format
  # [
  #   {
  #     "period_start": "2025-01-25T00:00:00Z",
  #     "period_end": "2025-01-25T23:59:59Z",
  #     "average": 22.5,
  #     "min": 18.0,
  #     "max": 27.0,
  #     "count": 144
  #   },
  #   ...
  # ]
  #
  # == Examples
  # GET /sensor_data/temperature_kitchen/daily-last/day
  # GET /sensor_data/temperature_kitchen/daily-last/week
  # GET /sensor_data/temperature_kitchen/daily-last/month?page=1&per=15
  # GET /sensor_data/temperature_kitchen/daily-last/year
  # GET /sensor_data/temperature_kitchen/daily-last/all
  #
  def daily_last_period
    sensor_code = params[:sensor_code]
    period = params[:period]

    return render json: { error: "sensor_code is required" }, status: :bad_request unless sensor_code
    return render json: { error: "Invalid period" }, status: :bad_request unless SensorDatum.valid_last_period?(period)

    summaries = SensorDatum
      .for_sensor(sensor_code)
      .in_last_period(period)
      .summarize_by_period('daily')
      .paginate(page: params[:page], per_page: params[:per])

    result = SensorDatum.format_summaries(summaries, 'daily')

    render json: result
  end

end
