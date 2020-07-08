require 'rails_helper'

RSpec.describe 'Sessions', type: :system do
    before do
        @user = create(:user)
    end

    it 'ログインページの要素検証' do
      visit 'users/sign_in'

      expect(page).to have_selector 'h1', text: 'ログインページ'
      expect(page).to have_field 'メールアドレス'
      expect(page).to have_field 'パスワード'
      expect(page).to have_button 'btn'
      expect(page).to have_link '新規登録ページへ'
      expect(page).to have_link 'パスワードをお忘れですか？'
    end

    describe '#new' do
      context 'ログインページで' do
        it 'email,passwordの両方が正しい場合、ログインが可能' do
          visit 'users/sign_in'
          # email,password共に未入力
          click_button 'btn'
          expect(page).to have_content 'メールアドレスまたはパスワードが違います。'
          # 誤ったemail
          fill_in 'メールアドレス', with: 'invalidemail@sample.com'
          fill_in 'パスワード', with: @user.password
          click_button 'btn'
          expect(page).to have_content 'メールアドレスまたはパスワードが違います。'
          # 誤ったpassword
          fill_in 'メールアドレス', with: @user.email
          fill_in 'パスワード', with: 'invalidpass'
          click_button 'btn'
          expect(page).to have_content 'メールアドレスまたはパスワードが違います。'
          # 有効なemail,password
          fill_in 'メールアドレス', with: @user.email
          fill_in 'パスワード', with: @user.password
          click_button 'btn'
          expect(page).to have_content 'ログインしました。'
          expect(page).to have_selector 'h1', text: '投稿一覧検索'
        end

        it '簡単ログインリンクを押すとゲストユーザーとしてログイン可能' do
          guest = create(:user, :guest)
          visit 'users/sign_in'
          click_link 'btn-guest'
          expect(page).to have_content 'ログインしました。'
          expect(page).to have_selector 'h1', text: '投稿一覧検索'
        end
      end
    end

    describe '#destroy' do
      context 'ログアウトリンクから' do
        it 'ログアウトが可能である' do
          visit 'users/sign_in'

          fill_in 'メールアドレス',with: @user.email
          fill_in 'パスワード',with: @user.password
          click_button 'btn'
          expect(page).to have_content 'ログインしました。'
          expect(page).to have_selector 'h1', text: '投稿一覧検索'

          # ヘッダーのドロップダウンを開く
          click_link 'logout'
          # 未ログイン状態のrootへリダイレクトされているか
          expect(page).to have_content 'ログアウトしました。'
        end
      end
    end

    describe 'ログイン状態で変化するページ' do
      context '未ログイン状態では' do
        it '未ログインユーザー用のページが表示される' do
          visit root_path
        end

        it 'ユーザー詳細ページにアクセスできない' do
          visit '/users/1'
          expect(page).to have_content 'アカウント登録もしくはログインしてください。'
        end

        it '新規投稿ページにアクセスできない' do
          visit '/maps/new'
          expect(page).to have_content 'アカウント登録もしくはログインしてください。'
        end

        it 'ユーザー検索ページにアクセスできない' do
          visit '/users'
          expect(page).to have_content 'アカウント登録もしくはログインしてください。'
        end

        it 'ユーザー情報編集ページにアクセスできない' do
          visit 'users/edit'
          expect(page).to have_content 'アカウント登録もしくはログインしてください。'
        end
      end
      context 'ログイン状態では' do
        it 'ログイン、新規登録ページにアクセスできない' do
          visit '/users/sign_in'

          fill_in 'メールアドレス', with: @user.email
          fill_in 'パスワード', with: @user.password
          click_button 'btn'
          expect(page).to have_content 'ログインしました。'
          expect(page).to have_selector 'h1', text: '投稿一覧検索'

          visit '/users/sign_in'
          expect(current_path).to eq root_path(@user)
          expect(page).to have_content 'すでにログインしています。'
          expect(page).to have_selector 'h1', text: '投稿一覧検索'

          visit '/users/sign_up'
          expect(current_path).to eq root_path(@user)
          expect(page).to have_content 'すでにログインしています。'
          expect(page).to have_selector 'h1', text: '投稿一覧検索'
        end
      end
    end

end