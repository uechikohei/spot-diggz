15.times do|n|
    title = Faker::Address.state
    content = Faker::Address.full_address
    user_id = "#{n+1}"
    latitude = Faker::Address.latitude
    longitude = Faker::Address.longitude
    picture_path = open("./db/fixtures/maps/#{n}.png")

    Map.create!(title: title,
        content: content,
        user_id: user_id,
        latitude: latitude,
        longitude: longitude,
        picture: picture_path,
    )
end