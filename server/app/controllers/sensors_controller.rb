class SensorsController < ApplicationController
    def index
        sensors = Sensor.all
        render json: sensors
    end
end
