Rails.application.configure do
  # 変更
  config.cache_classes = false
  config.eager_load = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # trueでレイアウトが崩れない。
  config.public_file_server.enabled = true

  config.assets.compile = true

  config.assets.initialize_on_precompile = false

  config.active_storage.service = :local

  config.log_level = :debug

  config.log_tags = [ :request_id ]

  config.action_mailer.perform_caching = false

  config.i18n.fallbacks = true

  config.active_support.deprecation = :notify

  config.log_formatter = ::Logger::Formatter.new

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  config.active_record.dump_schema_after_migration = false
  config.require_master_key = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.default_url_options = { host: 'sss.red-miso.work', :protocol => 'https' }
  config.action_mailer.logger = Logger.new('log/production_mail.log', 'weekly')
  config.action_mailer.raise_delivery_errors = true
  host = 'sss.red-miso.work'
  config.action_mailer.smtp_settings = {
    :address => "smtp.gmail.com",
    :port => '587',
    :authentication => :plain,
    :user_name => "SkateSpotSearch",
    :password => ENV['GMAIL_SECURE_PASS'],
    :domain => 'sss.red-miso.work',
    :enable_starttls_auto => true
}
end
