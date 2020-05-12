class Like < ApplicationRecord
  belongs_to :map
  belongs_to :user
  # いいねは１つの投稿に対しユーザ１人が１つしか付けれない
  validates_uniqueness_of :map_id, scope: :user_id
end
