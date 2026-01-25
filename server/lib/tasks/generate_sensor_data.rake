# lib/tasks/generate_sensor_data.rake
#
# Generate synthetic sensor data with sine wave patterns for testing/development.
#
# Usage:
#   rails sensor_data:generate              # Generate 30 days of data (default)
#   rails sensor_data:generate DAYS=90      # Generate 90 days of data
#   rails sensor_data:generate DAYS=7 INTERVAL=5  # 7 days, reading every 5 minutes
#   rails sensor_data:clear                 # Remove generated test sensors and data
#
namespace :sensor_data do
  desc "Generate synthetic sensor data with sine wave patterns"
  task generate: :environment do
    days = (ENV["DAYS"] || 30).to_i
    interval_minutes = (ENV["INTERVAL"] || 20).to_i  # Match ESP32 default sleep time

    puts "Generating #{days} days of sensor data (interval: #{interval_minutes} min)..."

    # Sensor 1: Temperature with 24h cycle (daily variation)
    # Peaks at 2pm (14:00), lowest at 2am
    temp_sensor = Sensor.find_or_create_by!(code: "temperature_test") do |s|
      s.name = "Temperature Test"
      s.units = "°C"
      s.value_type = "float"
    end

    # Sensor 2: Humidity with 24h + 7-day cycle (daily + weekly variation)
    # Daily: Higher at night, lower during day (inverse of temperature)
    # Weekly: Higher on weekends (less HVAC activity)
    humidity_sensor = Sensor.find_or_create_by!(code: "humidity_test") do |s|
      s.name = "Humidity Test"
      s.units = "%"
      s.value_type = "float"
    end

    # Clear existing data for these sensors
    SensorDatum.where(sensor_code: [temp_sensor.code, humidity_sensor.code]).delete_all

    # Time range: from `days` ago until now
    end_time = Time.current
    start_time = end_time - days.days
    current_time = start_time

    temp_data = []
    humidity_data = []

    while current_time <= end_time
      # Hours since start (for sine calculation)
      hours_elapsed = (current_time - start_time) / 1.hour

      # === Temperature: 24h sine wave ===
      # Base: 22°C, Amplitude: 4°C (range: 18-26°C)
      # Phase shift: peak at 14:00 (2pm)
      temp_base = 22.0
      temp_amplitude = 4.0
      temp_period_hours = 24.0
      temp_phase = -14.0 * (2 * Math::PI / temp_period_hours)  # Shift peak to 2pm

      temperature = temp_base + temp_amplitude * Math.sin(
        (2 * Math::PI * hours_elapsed / temp_period_hours) + temp_phase
      )
      # Add small random noise (±0.3°C)
      temperature += (rand - 0.5) * 0.6
      temperature = temperature.round(1)

      temp_data << {
        sensor_code: temp_sensor.code,
        value: temperature.to_s,
        created_at: current_time,
        updated_at: current_time
      }

      # === Humidity: 24h + 7-day sine waves ===
      # Base: 55%, Daily amplitude: 10%, Weekly amplitude: 5%
      # Daily: inverse of temperature (high at night, low during day)
      # Weekly: higher on weekends
      humidity_base = 55.0
      humidity_daily_amplitude = 10.0
      humidity_weekly_amplitude = 5.0
      daily_period_hours = 24.0
      weekly_period_hours = 24.0 * 7

      # Daily component (inverse phase from temperature - peak at 2am)
      humidity_daily = humidity_daily_amplitude * Math.sin(
        (2 * Math::PI * hours_elapsed / daily_period_hours) + temp_phase + Math::PI
      )

      # Weekly component (peak on Saturday)
      days_elapsed = hours_elapsed / 24.0
      saturday_offset = 5  # Saturday is day 5 (0=Monday)
      weekly_phase = -saturday_offset * (2 * Math::PI / 7.0)
      humidity_weekly = humidity_weekly_amplitude * Math.sin(
        (2 * Math::PI * days_elapsed / 7.0) + weekly_phase
      )

      humidity = humidity_base + humidity_daily + humidity_weekly
      # Add small random noise (±1%)
      humidity += (rand - 0.5) * 2.0
      humidity = humidity.clamp(30.0, 80.0).round(1)

      humidity_data << {
        sensor_code: humidity_sensor.code,
        value: humidity.to_s,
        created_at: current_time,
        updated_at: current_time
      }

      current_time += interval_minutes.minutes
    end

    # Bulk insert for performance
    SensorDatum.insert_all(temp_data)
    SensorDatum.insert_all(humidity_data)

    puts "✓ Created #{temp_data.size} temperature readings (#{temp_sensor.code})"
    puts "✓ Created #{humidity_data.size} humidity readings (#{humidity_sensor.code})"
    puts "  Date range: #{start_time.to_date} to #{end_time.to_date}"
  end

  desc "Clear generated test sensor data"
  task clear: :environment do
    test_codes = %w[temperature_test humidity_test]
    deleted_data = SensorDatum.where(sensor_code: test_codes).delete_all
    deleted_sensors = Sensor.where(code: test_codes).delete_all
    puts "✓ Deleted #{deleted_data} data points and #{deleted_sensors} sensors"
  end
end
