class CreateSensorData < ActiveRecord::Migration[8.0]
  def change
    create_table :sensor_data do |t|
      t.string :sensor_code
      t.string :value

      t.timestamps
    end
  end
end
