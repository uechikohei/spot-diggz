class AddPictureMaps < ActiveRecord::Migration[6.0]
  def change
    add_column :maps, :picture, :string
    add_column :maps, :content, :text
    add_column :maps, :title, :string
  end
end
