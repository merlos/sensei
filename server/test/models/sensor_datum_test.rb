require "test_helper"

class SensorDatumTest < ActiveSupport::TestCase
    test "can create sensor data" do
        Sensor.create!(code: "pressure_room", name: "Pressure", units: "Pa", value_type: "float")
        data = SensorDatum.new(sensor_code: "pressure_room", value: "101325")
        assert data.save
    end

    test "cannot create sensor data with all info" do
        Sensor.create!(code: "pressure_room", name: "Pressure", units: "Pa", value_type: "float")
        data = SensorDatum.new(sensor_code: "presure_room")
        assert_not data.valid?
    end
end
