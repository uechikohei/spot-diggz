class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :validatable

  has_many :maps, dependent: :destroy

  mount_uploader :image, ImageUploader
  validates :name, presence: true, length: { maximum: 80}

  # 最近作成されたユーザーから表示
  default_scope -> { order(created_at: :desc) }
  # 一度に表示する投稿数
  paginates_per 6

  # 簡単ログインユーザー作成
  def self.guest
    image_path = open("./db/fixtures/faker_user_image.png")
    find_or_create_by!(email: 'guest@example.com') do |user|
      user.password = SecureRandom.urlsafe_base64
      user.name = "guest"
      user.image = image_path
      # user.confirmed_at = Time.now  # Confirmable を使用している場合は必要
    end
  end
end
