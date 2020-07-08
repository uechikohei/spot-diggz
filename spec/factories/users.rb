FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "sample#{n}" }
    sequence(:email)        { |n| "sample#{n}@sample.com" }
    password                { 'password' }
    password_confirmation   { 'password' }
  end
end
