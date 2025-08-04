# app/controllers/sensor_data_controller.rb
class SensorDataController < ApplicationController
  skip_before_action :verify_authenticity_token

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
    SensorData.create!(sensor_code: sensor_code, value: value)

    render json: { status: 'ok' }, status: :created
  end
end
