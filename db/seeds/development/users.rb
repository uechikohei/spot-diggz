10.times do|n|
    name = Faker::Games::Pokemon.name
    email = Faker::Internet.email
    password = "1111"
    image_path = open("./db/fixtures/faker_user_image.png")
    User.create!(name: name,
        email: email,
        password: password,
        password_confirmation: password,
        image: image_path,
    )
end