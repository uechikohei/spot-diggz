15.times do|n|
    address = Faker::Address.city
    title = Faker::Address.state
    content = Faker::Address.full_address
    user_id = "#{n+1}"
    # Faker::Address.latitudeとlongitudeを使用すると、位置情報取得できない
    latitude = "35.652832"
    longitude = "139.703865"
    picture_path = open("./db/fixtures/users/#{n+1}.png")

    Map.create!(address: address,
        title: title,
        content: content,
        user_id: user_id,
        latitude: latitude,
        longitude: longitude,
        picture: picture_path,
    )
end