require 'rails_helper'

RSpec.describe 'Maps', type: :system do

  describe '#new,#show,#destroy' do
    context 'ログインしたとき' do
      before do
        @user = create(:user)
        visit 'users/sign_in'
        fill_in 'メールアドレス', with: @user.email
        fill_in 'パスワード', with: @user.password
        click_button 'btn'
        expect(page).to have_content 'ログインしました。'
        expect(page).to have_selector 'h1', text: '投稿一覧検索'
      end

      it '新規投稿ページの要素が正しく表示される' do
        visit '/maps/new'

        expect(page).to have_selector '#newpost'
        expect(page).to have_selector 'h3',text: 'どんなスポット？'
        expect(page).to have_selector 'h3',text: 'ヘルメットの着用義務は？'
        expect(page).to have_selector 'h3',text: 'スケートパークやスポット名は？'
        expect(page).to have_selector 'h3',text: '説明や備考などあれば'
        expect(page).to have_selector 'h3',text: '写真をアップロード'
        expect(page).to have_button 'btn'
      end
    end
  end
end