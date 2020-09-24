Rails.application.configure do
  config.cache_classes = false
  config.eager_load = false
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }

  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  config.action_dispatch.show_exceptions = false

  config.action_controller.allow_forgery_protection = false

  config.active_storage.service = :test

  config.action_mailer.perform_caching = false

  config.active_support.deprecation = :stderr

  #devise本人認証(Amazon SES smtp setting)
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
      :address => 'email-smtp.ap-northeast-1.amazonaws.com',
      :port => 587,
      :authetication => :login,
      :user_name => ENV['AWS_SES_KEY_ID'],
      :password => ENV['AWS_SES_PASSWORD'],
      :enable_starttls_auto => true
  }
end