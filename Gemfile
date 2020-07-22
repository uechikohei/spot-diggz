source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.5'

gem "bcrypt"
gem 'bootsnap', '>= 1.4.2', require: false
gem "date_validator"
gem 'jbuilder', '~> 2.7'
gem 'mysql2', '>= 0.4.4'
gem "nokogiri"
gem 'puma', '~> 4.3'
gem 'rails', '~> 6.0.2', '>= 6.0.2.1'
gem "rails-i18n"
gem 'sass-rails', '>= 6'
gem 'turbolinks', '~> 5'
gem "valid_email2"
gem 'webpacker', '~> 4.0'
# ユーザー認証
gem 'devise', '~> 4.7', '>= 4.7.1'
# google maps 検索移動
gem 'carrierwave', '~> 2.1'
gem 'faker', '~> 2.11'
gem 'fog-aws', '~> 3.6', '>= 3.6.2'
gem 'geocoder', '~> 1.6', '>= 1.6.2'
gem 'gon', '~> 6.3', '>= 6.3.2'
gem 'image_magick', '~> 0.1.9'
gem 'image_processing', '~> 1.10', '>= 1.10.3'
gem 'kaminari'
gem 'mini_magick', '~> 4.10', '>= 4.10.1'
gem 'omniauth', '~> 1.9', '>= 1.9.1'
gem 'omniauth-twitter', '~> 1.4'
gem 'ransack', '~> 2.3', '>= 2.3.2'
gem 'rmagick', '~> 4.1', '>= 4.1.1'

group :test do
  gem "capybara", ">= 2.15"
  gem "selenium-webdriver"
end

group :development, :test do
  gem 'factory_bot_rails'
  gem 'pry-byebug', '~> 3.9'
  gem 'pry-rails', '~> 0.3.9'
  gem 'rspec-rails'
  gem 'rubocop', require: false
  gem 'rubocop-rails'
  gem 'spring-commands-rspec'

end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
end

gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
