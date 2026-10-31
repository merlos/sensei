class AddGroupNameToSensors < ActiveRecord::Migration[8.0]
  def change
    add_column :sensors, :group_name, :string
  end
end
