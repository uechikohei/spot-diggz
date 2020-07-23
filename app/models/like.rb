class Like < ApplicationRecord
  belongs_to :map
  belongs_to :user
  # いいねは１つの投稿に対しユーザ１人が１つしか付けれない
  validates :map_id, uniqueness: { scope: :user_id }
end
