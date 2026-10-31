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

  test "group_name is optional and blank values are normalized to nil" do
    sensor = Sensor.create!(code: "no_group", group_name: "   ")
    assert_nil sensor.group_name
  end

  test "group_name is stripped and limited to 50 chars" do
    sensor = Sensor.create!(code: "with_group", group_name: "  Kitchen ")
    assert_equal "Kitchen", sensor.group_name
    assert_not Sensor.new(code: "long_group", group_name: "a" * 51).valid?
  end

  test "groups returns distinct sorted group names" do
    Sensor.create!(code: "g1", group_name: "Living room")
    Sensor.create!(code: "g2", group_name: "Kitchen")
    Sensor.create!(code: "g3", group_name: "Kitchen")
    Sensor.create!(code: "g4")
    assert_equal ["Kitchen", "Living room"], Sensor.groups
  end
end
