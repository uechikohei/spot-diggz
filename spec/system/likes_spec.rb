require 'rails_helper'

RSpec.describe 'Likes', type: :system, js: true do
    describe '#create,#destroy' do
        it 'ユーザーが他の投稿をいいね、いいね解除できる' do
            markus = create(:user,
                            name:  'markus',
                            email: 'markus@email.com')
            post   = create(:map)

            visit 'users/sign_in'
            fill_in 'メールアドレス', with: markus.email
            fill_in 'パスワード', with: markus.password
            click_button 'btn'
            expect(page).to have_content 'ログインしました。'

            # 投稿のページへ
            visit "/maps/#{post.id}"
            expect(page).to have_selector 'h1', text: 'ROUTE MAP'

            # upリンクをクリック。activeクラスが足されることを確認
            find('.drawer').click
            expect(page).to have_css '.active'

            # いいねをするボタンを押す
            find('#nolike-btn').click
            expect(page).to have_selector '#liking-btn'
            expect(post.likes.count).to eq(1)

            # いいねを解除する
            find('#liking-btn').click
            expect(page).to have_selector '#nolike-btn'
            expect(post.likes.count).to eq(0)
        end
    end
end