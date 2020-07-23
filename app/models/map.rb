class Map < ApplicationRecord
  mount_uploader      :picture, PictureUploader
  reverse_geocoded_by :latitude, :longitude
  after_validation    :reverse_geocode
  before_validation   :kill_whitespace

  validates :user_id,     presence: true
  validates :title,       presence: true,
                          length: { maximum: 20 }

  validates :content,     presence: true,
                          length: { maximum: 300 }

  validates :latitude,    presence: true
  validates :longitude,   presence: true

  # user.rbのhas_manyに対応する
  belongs_to  :user
  # likeテーブルと1対多になる
  has_many    :likes
  # 投稿が、どのユーザにいいねされているか取得
  has_many    :liked_users, through: :likes, source: :user
  # commentテーブルと1対多になる
  has_many :comments, dependent: :destroy

  # 最近作成されたユーザーから表示
  default_scope -> { order(created_at: :desc) }
  # 一度に表示する投稿数
  paginates_per 6

  def self.search(address)
    return Map.all unless address

    Map.where(['content LIKE ?', "%#{address}%"])
  end

  private

    # 投稿時のタイトルに入力されるスペースを削除する
    def kill_whitespace
      self.title = title.gsub(/[[:space:]]/, '') if self.title.present?
    end
end
