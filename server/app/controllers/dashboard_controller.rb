# Dashboard controller for web UI
# Provides a web interface for viewing and managing sensor data
class DashboardController < ApplicationController
  def index
    @sensors = Sensor.all.order(:name)
    @total_readings = SensorDatum.count
    @latest_readings = SensorDatum.order(created_at: :desc).limit(10)
  end

  def sensor
    @sensor = Sensor.find_by!(code: params[:code])
    @readings = SensorDatum
      .where(sensor_code: @sensor.code)
      .order(created_at: :desc)
      .limit(100)
  rescue ActiveRecord::RecordNotFound
    redirect_to dashboard_path, alert: "Sensor not found"
  end
end
