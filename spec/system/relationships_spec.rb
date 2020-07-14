require 'rails_helper'

RSpec.describe 'Relationships', type: :system, js: true do
    describe '#create,#destroy' do
        it 'ユーザーをフォロー、フォロー解除できる' do
            hank    = create(:user,
                            name:  'hank',
                            email: 'hank@email.com')
            connor  = create(:user,
                            name:  'connor',
                            email: 'connor@email.com')

            # hankがログイン
            visit 'users/sign_in'
            fill_in 'メールアドレス', with: hank.email
            fill_in 'パスワード', with: hank.password
            click_button 'btn'
            expect(page).to have_content 'ログインしました。'

            visit user_path(connor)
            expect(page).to have_selector 'h2', text: '@ connor'

            # connorをフォローする
            find('#no-follow').click
            expect(page).to have_selector '#yes-follow'
            expect(connor.followed.count).to eq(1)
            expect(hank.follower.count).to eq(1)

            # connorをフォロー解除する
            find('#yes-follow').click
            expect(page).to have_selector '#no-follow'
            expect(connor.followed.count).to eq(0)
            expect(hank.follower.count).to eq(0)
        end
    end
end