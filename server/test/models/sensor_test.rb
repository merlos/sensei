require "test_helper"

class SensorTest < ActiveSupport::TestCase
  test "valid sensor" do
    sensor = Sensor.new(code: "temperature_kitchen", name: "Temperature", units: "C", value_type: "float")
    assert sensor.valid?
  end

  test "invalid without code" do
    sensor = Sensor.new(name: "No Code")
    assert_not sensor.valid?
  end

  test "code uniqueness" do
    Sensor.create!(code: "humidity", name: "Humidity", units: "%", value_type: "float")
    duplicate = Sensor.new(code: "humidity")
    assert_not duplicate.valid?
  end
end
