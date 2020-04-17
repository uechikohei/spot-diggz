class AddUserIdToMaps < ActiveRecord::Migration[6.0]
  def change
    add_column :maps, :user_id, :integer
  end
end
