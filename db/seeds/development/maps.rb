20.times do|n|
    address = Faker::Address.city
    title = "ここにタイトル"
    content = "本文"
    user_id = "1"
    latitude = "35.652832"
    longitude = "139.703865"

    Map.create!(address: address,
        title: title,
        content: content,
        user_id: user_id,
        latitude: latitude,
        longitude: longitude,
    )
end