15.times do|n|
    name = Faker::Games::Pokemon.name
    email = Faker::Internet.email
    password = "1111"
    image_path = open("./db/fixtures/users/#{n+1}.png")
    User.create!(name: name,
        email: email,
        password: password,
        password_confirmation: password,
        image: image_path,
    )
end