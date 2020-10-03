Rails.application.configure do
  # 変更
  config.cache_classes = false
  config.eager_load = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # public以下を静的ファイルとして取り扱う
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

  config.serve_static_files = ENV['RAILS_SERVE_STATIC_FILES'].present?

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  #master.keyがない環境では起動エラーにする
  config.require_master_key = true

  #ログ出力
  config.action_mailer.logger = Logger.new('log/production_mail.log', 'weekly')

  # derault url
  config.action_mailer.default_url_options = { protocol: 'https',host: 'sss.red-miso.work' }

# Amazon SES smtp setting
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
      :address => 'email-smtp.ap-northeast-1.amazonaws.com',
      :port => 587,
      :authetication => :login,
      :user_name => Rails.application.credentials.aws_ses[:user_name],
      :domain => 'red-miso.work',
      :password => Rails.application.credentials.aws_ses[:password],
      :enable_starttls_auto => true
  }
end