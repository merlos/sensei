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

  def update_sensor
    @sensor = Sensor.find_by!(code: params[:code])
    field = params[:field]
    value = params[field]
    
    if @sensor.update(field => value)
      render json: { status: 'success', value: @sensor.send(field) }
    else
      render json: { status: 'error', errors: @sensor.errors.full_messages }
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: 'error', message: 'Sensor not found' }, status: 404
  end

  def delete_sensor
    @sensor = Sensor.find_by!(code: params[:code])
    
    # Delete all associated sensor data first
    SensorDatum.where(sensor_code: @sensor.code).delete_all
    
    # Then delete the sensor
    @sensor.destroy!
    
    render json: { status: 'success' }
  rescue ActiveRecord::RecordNotFound
    render json: { status: 'error', message: 'Sensor not found' }, status: 404
  end

  def update_reading
    @reading = SensorDatum.find(params[:id])
    
    if @reading.update(value: params[:value])
      render json: { status: 'success', value: @reading.value }
    else
      render json: { status: 'error', errors: @reading.errors.full_messages }
    end
  rescue ActiveRecord::RecordNotFound
    render json: { status: 'error', message: 'Reading not found' }, status: 404
  end

  def destroy_reading
    @reading = SensorDatum.find(params[:id])
    @reading.destroy!
    render json: { status: 'success' }
  rescue ActiveRecord::RecordNotFound
    render json: { status: 'error', message: 'Reading not found' }, status: 404
  end

  private

  # No longer needed - handling parameters directly
end
