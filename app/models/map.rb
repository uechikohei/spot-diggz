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
  has_many    :likes,       dependent: :destroy
  # 投稿が、どのユーザにいいねされているか取得
  has_many    :liked_users, through: :likes,    source: :user
  # commentテーブルと1対多になる
  has_many    :comments,    dependent: :destroy

  # 最近作成されたユーザーから表示
  default_scope -> { order(created_at: :desc) }
  # 一度に表示する投稿数
  paginates_per 6

  enum pref_area:{
    北海道:0,青森県:1,岩手県:2,宮城県:3,秋田県:4,山形県:5,福島県:6,
    茨城県:7,栃木県:8,群馬県:9,埼玉県:10,千葉県:11,東京都:12,神奈川県:13,
    新潟県:14,富山県:15,石川県:16,福井県:17,山梨県:18,長野県:19,
    岐阜県:20,静岡県:21,愛知県:22,三重県:23,
    滋賀県:24,京都府:25,大阪府:26,兵庫県:27,奈良県:28,和歌山県:29,
    鳥取県:30,島根県:31,岡山県:32,広島県:33,山口県:34,
    徳島県:35,香川県:36,愛媛県:37,高知県:38,
    福岡県:39,佐賀県:40,長崎県:41,熊本県:42,大分県:43,宮崎県:44,鹿児島県:45,沖縄県:46
  }

  def self.search(address)
    return Map.all unless address

    Map.where(['content LIKE ?', "%#{address}%"])
  end

  private

    # 投稿時のタイトルに入力されるスペースを削除する
    def kill_whitespace
      self.title = title.gsub(/[[:space:]]/, '') if title.present?
    end
end
