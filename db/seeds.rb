table_names = %w(users)

table_names.each do
    |table_name|

    path = Rails.root.join("db", "seeds", Rails.env, "#{table_name}.rb")
    if File.exist?(path)
        puts "Creating #{table_name}...."
        require(path)
    end
end
