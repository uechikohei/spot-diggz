20.times do|n|
    address = Faker::Address.city
    title = "サンプルタイトル"
    content = "rails db:seedで投入したよ"
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