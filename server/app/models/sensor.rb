class Sensor < ApplicationRecord
    validates :code, presence: true, uniqueness: true
end
