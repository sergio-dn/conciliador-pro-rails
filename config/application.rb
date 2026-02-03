require_relative 'boot'

require 'rails'
require 'active_model/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'sprockets/railtie'

Bundler.require(*Rails.groups)

module ReconciliacionRails
  class Application < Rails::Application
    config.load_defaults 7.1
    config.autoload_lib(ignore: %w[assets tasks])

    # No database needed
    config.generators do |g|
      g.orm false
    end

    # Session configuration
    config.session_store :cookie_store, key: '_reconciliacion_session'
  end
end
