require 'rails_helper'

RSpec.describe User, type: :model do

  # 姓、名、メール、パスワードがあれば有効な状態であること
  it "name, email, password があれば有効な状態である" do
    user = User.new(
      name: 'sample user',
      email: 'example@sample.com',
      password: 'password',
      password_confirmation: 'password'
    )
    expect(user).to be_valid
  end

  # 名がなければ無効な状態であること
  it "is invalid without a first name"

  # 姓がなければ無効な状態であること
  it "is invalid without a last name"

  # メールアドレスがなければ無効な状態であること
  it "is invalid without an email address"

  # 重複したメールアドレスなら無効な状態であること
  it "is invalid with a duplicate email address"

  # ユーザーのフルネームを文字列として返すこと
  it "returns a user's full name as a string"

end
