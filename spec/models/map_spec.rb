require 'rails_helper'

RSpec.describe Map, type: :model do
  let(:map) { create(:map) }

  it 'mapモデルにて、投稿が可能である' do
    expect(map).to be_valid
  end

  it 'userが存在しない投稿はエラー' do
    map.user_id = nil
    map.valid?
    expect(map.errors).to be_added(:user_id, :blank)
  end

  it 'titleがnilの場合、投稿はエラー' do
    map.title = nil
    map.valid?
    expect(map.errors).to be_added(:title, :blank)
  end

  it 'titleが空の場合、投稿はエラー' do
    map.title = ''
    map.valid?
    expect(map.errors).to be_added(:title, :blank)
  end

  it 'titleが20文字以下の場合、投稿を許可する' do
    map.title = 'a' * 20
    expect(map).to be_valid
  end

  it 'titleが21文字以上の場合、エラー' do
    map.title = 'a' * 21
    map.valid?
    expect(map.errors).to be_added(:title, :too_long, count: 20)
  end

end
