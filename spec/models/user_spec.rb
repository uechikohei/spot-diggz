require 'rails_helper'

RSpec.describe User, type: :model do

  it "name, email, password があれば有効な状態である" do
    user = User.new(
      name: 'sample user',
      email: 'sample@sample.com',
      password: 'password',
      password_confirmation: 'password'
    )
    expect(user).to be_valid
  end

  it 'ユーザー登録が可能である' do
    expect(build(:user)).to be_valid
  end

  it "nameを持たないユーザーを許可しない" do
    user = User.new(name: nil)
    user.save
    user.valid?
    expect(user.errors[:name]).to include("cant't be blank!")
  end

  # 姓がなければ無効な状態であること
  it "is invalid without a last name"

  # メールアドレスがなければ無効な状態であること
  it "is invalid without an email address"

  # 重複したメールアドレスなら無効な状態であること
  it "is invalid with a duplicate email address"

  # ユーザーのフルネームを文字列として返すこと
  it "returns a user's full name as a string"

end
