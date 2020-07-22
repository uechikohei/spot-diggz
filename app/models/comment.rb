class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :map
  # バリデーション
  validates :content, presence: true
end
