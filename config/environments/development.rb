Rails.application.configure do
  config.cache_classes = false
  config.eager_load = false
  config.consider_all_requests_local = true

  config.webpacker.check_yarn_integrity = false

  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  config.active_storage.service = :local

  config.action_mailer.perform_caching = false
  config.active_support.deprecation = :log
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true
  config.assets.debug = true
  config.assets.quiet = true
  
  # deviseインストール設定１
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }

  config.file_watcher = ActiveSupport::EventedFileUpdateChecker
  config.web_console.whitelisted_ips= '0.0.0.0/0'

  if Rails.application.credentials.gmail.present?
    mail_address = Rails.application.credentials.gmail[:address]
    password = Rails.application.credentials.gmail[:password]
  else
    mail_address = 'admin@example.com'
    password = 'password'
  end


  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    enable_starttls_auto: true,
    address: "smtp.gmail.com",
    port: 587,
    user_name: mail_address,
    password: password,
    authentication: "plain"
}
end
