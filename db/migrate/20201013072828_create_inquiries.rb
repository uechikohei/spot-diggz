class CreateInquiries < ActiveRecord::Migration[6.0]
  def change
    create_table :inquiries do |t|
      t.string :name
      t.string :mail
      t.string :message

      t.timestamps
    end
  end
end
