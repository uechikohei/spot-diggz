require 'rails_helper'

RSpec.describe 'Sign_up', type: :system do

  it '新規登録ページの各要素を検証' do
    #アクセス先
    visit '/users/sign_up'
    #　該当ページindex.htmlいタグとテキストが存在してるか確認
    expect(page).to have_selector 'h1', text: 'ようこそ！'
    expect(page).to have_selector 'h2', text: 'アカウントを作成しよう'
    expect(page).to have_selector 'h3', text: 'プロフ画像を設定'
    expect(page).to have_selector 'h3', text: 'アカウント情報を入力'
    expect(page).to have_field '名前 (2文字以上)'
    expect(page).to have_field 'メールアドレス'
    expect(page).to have_field 'パスワード（４文字以上）'
    expect(page).to have_field 'image-default'
    expect(page).to have_button 'btn'
  end


  describe 'registrations#new' do
    it 'ユーザーを新規登録可能' do
      # ページにアクセスする
      visit '/users/sign_up'
      # formにテキストを入力する
      fill_in '名前 (2文字以上)',       with: 'tester'
      fill_in 'メールアドレス',         with: 'tester@example.com'
      fill_in 'パスワード（４文字以上）', with: '1234'
      # button_tag の　id: "btn"をクリックしてフォームを送信。
      click_button 'btn'
      # ページ内に、'テキスト'を含むものがあるかどうか確認する。
      expect(page).to have_content '本人確認用のメールを送信しました。'
    end

    it '各入力欄に適切な値が入力されていない新規登録を許可しない' do
      visit '/users/sign_up'
      # formにテキストを入力する
      fill_in '名前 (2文字以上)',       with: ''
      fill_in 'メールアドレス',         with: ''
      fill_in 'パスワード（４文字以上）', with: ''
      # button_tag の　id: "btn"をクリックしてフォームを送信。
      click_button 'btn'
      #　入力フォームが空欄の場合
      expect(page).to have_content '名前を入力してください'
      expect(page).to have_content 'パスワードを入力してください'
      expect(page).to have_content 'メールアドレスを入力してください'
      expect(page).to have_content '名前は2文字以上で入力してください'
    end

  end

end