class SensorsController < ApiController
    def index
        sensors = Sensor.all
        render json: sensors
    end
end
