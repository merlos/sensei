

class SensorDatum < ApplicationRecord
    validates :sensor_code, presence: true
    validates :value, presence: true
end