require 'rails_helper'

RSpec.describe 'Sign_up', type: :system do

  it '新規登録ページの要素検証' do
    #ページが表示されるか検証
    visit '/users/sign_up'
  end

end