class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :validatable

  mount_uploader :image, ImageUploader
  validates :name, presence: true, length: { maximum: 80}

  # 簡単ログインユーザー作成
  def self.guest
    image_path = open("./db/fixtures/faker_user_image.png")
    find_or_create_by!(email: 'guest@example.com') do |user|
      user.password = SecureRandom.urlsafe_base64
      user.name = "guest_user"
      user.image = image_path
      # user.confirmed_at = Time.now  # Confirmable を使用している場合は必要
    end
  end
end
