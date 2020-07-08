FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "sample#{n}" }
    sequence(:email)        { |n| "sample#{n}@sample.com" }
    password                { 'password' }
    password_confirmation   { 'password' }
  end

  trait :guest do
    name     { 'guest_user' }
    email    { 'guest@example.com' }
    password { 'password' }
  end

end
