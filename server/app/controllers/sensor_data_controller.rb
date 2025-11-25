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
 
# GET /sensor_data?sensor_code=...&after=...&before=...&page=1&per=100
# Eg: GET /sensor_data/temperature_kitchen?after=2025-08-01T00:00:00Z&before=2025-08-06T00:00:00Z&page=1&per=20

def index

    sensor_code = params[:sensor_code]
    return render json: { error: "sensor_code is required" }, status: :bad_request unless sensor_code

    data = SensorDatum.where(sensor_code: sensor_code)

    if params[:after].present?
      after_time = Time.iso8601(params[:after]) rescue nil
      data = data.where("created_at >= ?", after_time) if after_time
    end

    if params[:before].present?
      before_time = Time.iso8601(params[:before]) rescue nil
      data = data.where("created_at <= ?", before_time) if before_time
    end

    page = params[:page].to_i > 0 ? params[:page].to_i : 1
    per_page = params[:per].to_i > 0 ? [params[:per].to_i, 1000].min : 50
    data = data.order(created_at: :desc).offset((page - 1) * per_page).limit(per_page)

    render json: data
  end

end
