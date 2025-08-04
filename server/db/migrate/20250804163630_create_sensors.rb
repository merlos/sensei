class CreateSensors < ActiveRecord::Migration[8.0]
  def change
    create_table :sensors do |t|
      t.string :code
      t.string :name
      t.string :units
      t.string :value_type

      t.timestamps
    end
    add_index :sensors, :code, :unique: true
  end
end
