10.times do|n|
    name = Faker::Games::Pokemon.name
    email = Faker::Internet.email
    password = "1111"
    User.create!(name: name,
        email: email,
        password: password,
        password_confirmation: password,
    )
end