20.times do|n|
    address = Faker::Address.city
    title = "ここにタイトル"
    content = "本文"
    user_id = "1"
    Map.create!(address: address,
        title: title,
        content: content,
        user_id: user_id,
    )
end