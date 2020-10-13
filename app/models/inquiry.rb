class Inquiry < ApplicationRecord
  attr_accessor :name, :mail, :message

  validates :name, presence: { message: '名前を入力してください' }
  validates :mail, presence: { message: 'メールアドレスを入力してください' }
end
