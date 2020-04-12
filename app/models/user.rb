class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :validatable
          has_many :maps

  mount_uploader :image, ImageUploader

  validates :image_name, length: { maximum: 200 } #追記
  validates :name, presence: true, length: { maximum: 80}
end
