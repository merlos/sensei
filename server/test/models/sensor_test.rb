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

  test "invalid with special characters in code" do
    sensor = Sensor.new(code: "temp@123", name: "Bad Code")
    assert_not sensor.valid?
  end

  test "invalid when code is too long" do
    long_code = "a" * 51
    sensor = Sensor.new(code: long_code, name: "Too Long")
    assert_not sensor.valid?
  end
  
end
