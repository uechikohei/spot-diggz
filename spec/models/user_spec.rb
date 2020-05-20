require 'rails_helper'

RSpec.describe User, type: :model do

  before do
    @user = build(:user)
  end

  it 'ユーザー登録が可能である' do
    expect(build(:user)).to be_valid
  end

  describe 'validations' do
    it "name, email, password があれば有効な状態である" do
      user = User.new(
        name: 'sample user',
        email: 'sample@sample.com',
        password: 'password'
      )
      expect(user).to be_valid
    end

    it "nameがnilでエラー時、エラーメッセージが出る" do
      @user.name = nil
      @user.valid?
      expect(@user.errors).to be_added(:name, :blank)
    end

    it "emailがnilでエラー時、エラーメッセージが出る" do
      @user.email = nil
      @user.valid?
      expect(@user.errors).to be_added(:email, :blank)
    end

    it "passwordがnilでエラー時、エラーメッセージが出る" do
      @user.password = nil
      @user.valid?
      expect(@user.errors).to be_added(:password, :blank)
    end

    it 'emailが255文字以下のユーザーを許可する' do
      @user.email = 'a' * 245 + '@sample.jp'
      expect(@user).to be_valid
    end

    it 'emailが256文字以上のユーザーを許可しない' do
      @user.email = 'a' * 246 + '@sample.jp'
      @user.valid?
      expect(@user.errors).to be_added(:email, :too_long, count: 255)
    end

    it 'passwordが4文字未満でエラー' do
      @user.password = 'a' * 3
      @user.valid?
      expect(@user.errors).to be_added(:password, :too_short, count: 4)
    end

    it 'passwordが4文字以上で作成可能' do
      @user.password = @user.password_confirmation = 'a' * 4
      expect(@user).to be_valid
    end

    it "nameが重複しているとエラー" do
      user  = create(:user, name: 'tester')
      user2 = build(:user, name: 'tester')
      user2.valid?
      expect(user2.errors).to be_added(:name, :taken, value: 'tester')
    end

    it 'nameが2文字未満のユーザーはエラー' do
      @user.name = 'a' * 1
      @user.valid?
      expect(@user.errors).to be_added(:name, :too_short, count: 2)
    end

    it 'nameが21文字以上のユーザーはエラー' do
      @user.name = 'a' * 21
      @user.valid?
      expect(@user.errors).to be_added(:name, :too_long, count: 20)
    end

    it "nameは大文字小文字を区別できる" do
      user  = create(:user, name: 'tester')
      user2 = build(:user, name: 'Tester')
      expect(user2).to be_valid
    end

    it 'emailが重複しているとエラー' do
      user  = create(:user, email: 'sample@sample.jp')
      user2 = build(:user, email: 'sample@sample.jp')
      user2.valid?
      expect(user2.errors).to be_added(:email, :taken, value: 'sample@sample.jp')
    end

    it 'emailが255文字以下のユーザーが作成可能' do
      @user.email = 'a' * 245 + '@sample.jp'
      expect(@user).to be_valid
    end

    it 'emailが256文字以上のユーザーは作成できない' do
      @user.email = 'a' * 246 + '@sample.jp'
      @user.valid?
      expect(@user.errors).to be_added(:email, :too_long, count: 255)
    end
  end

  it 'emailは全て小文字で保存される' do
    @user.email = 'SAMPLE@SAMPLE.JP'
    @user.save!
    expect(@user.reload.email).to eq 'sample@sample.jp'
  end

  it'ユーザーが他のユーザーをフォロー、フォロー解除可能である' do
    tester1   = create(:user)
    tester2   = create(:user)
    tester1.follow(tester2.id)
    expect(tester1.following?(tester2)).to eq true
    tester1.unfollow(tester2.id)
    expect(tester1.following?(tester2)).to eq false
  end

  it 'フォロー中のユーザーが削除されると、フォローが解消される' do
    tester1   = create(:user)
    tester2   = create(:user)
    tester1.follow(tester2.id)
    expect(tester1.following?(tester2)).to eq true
    tester1.destroy
    expect(tester1.following?(tester2)).to eq false
  end

  it 'フォローされているユーザーが削除されると、フォローされていた状態が解消される' do
    tester1   = create(:user)
    tester2   = create(:user)
    tester1.follow(tester2.id)
    expect(tester1.following?(tester2)).to eq true
    tester2.destroy
    expect(tester1.following?(tester2)).to eq false
  end
end
