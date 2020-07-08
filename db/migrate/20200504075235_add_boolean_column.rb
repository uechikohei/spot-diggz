class AddBooleanColumn < ActiveRecord::Migration[6.0]
  def change
    add_column :maps, :helmet, :boolean, default: false, null: false
    add_column :maps, :spot_style, :boolean, default: true, null: true
  end
end
