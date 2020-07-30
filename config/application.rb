require_relative 'boot'

require "rails"

require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
require "sprockets/railtie"

Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    config.load_defaults 6.0
    # 取り除くと、Zeitwerkモードで起動
    config.autoloader = :classic
    config.time_zone = "Tokyo"

    #　#　以下の記述を追記する(設定必須)
    config.i18n.load_path += Dir[Rails.root.join("config","locales","**","*.{rb,yml}").to_s]
    config.action_view.embed_authenticity_token_in_remote_forms = true
    config.i18n.default_locale = :ja
    config.generators.system_tests = nil
    config.generators do |g|
      g.skip_routes true
      g.helper false
      g.assets false
      g.test_framework :rspec
      g.controller_specs false
      g.view_specs false
      g.test_framework :rspec,
        view_specs: false,
        helper_specs: false,
        routing_specs: false,
        request_specs: false
    end
  end
end


