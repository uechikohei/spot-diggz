class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :map
  validates :content, presence: true
end
