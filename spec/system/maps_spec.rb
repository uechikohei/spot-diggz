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

      it '新規投稿、投稿削除が可能' ,js: true do
        visit '/maps/new'

        # スポットを検索する
        fill_in 'address', with: "大阪　スケートパーク"
        click_button 'map_button'
        # スポットのタイトルと本文を入力
        select  'スケートパーク', from: 'map_spot_style'
        select  '有り', from: 'map_helmet'
        fill_in 'map_title', with: "サンプルスケートパーク"
        fill_in 'map_content', with: "サンプルテキスト"
        attach_file 'map_picture',"#{Rails.root}/spec/fixtures/test.png", visible: false
        # 投稿
        click_button 'btn'
        # 投稿showページへリダイレクトしている。
        @map = Map.first
        expect(page).to have_current_path "/maps/#{@map.id}"
        # 成功メッセージ
        expect(page).to have_content '新しいスポットが無事登録されました！'
        expect(page).to have_selector 'h1', text: 'ROUTE MAP'

        # 投稿が保存されているか
        expect(@map.title).to   eq("サンプルスケートパーク")
        expect(@map.content).to eq("サンプルテキスト")
        # 削除ボタンを押し出現するダイアログをOKとする
        page.accept_confirm('本当に削除してもよろしいですか?') do
          click_on :delete_btn
        end
        # 投稿が削除されているか
        expect(Map.where(id: @user.id).count).to eq 0
        # 削除ボタンを押し出現するダイアログを閉じる
      end

    end
  end
end