require 'active_support/core_ext/integer/time'

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  
  # Forzar servidor de archivos estáticos para Render
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present? || true
  
  config.force_ssl = true
  config.assume_ssl = true

  config.log_tags = [:request_id]
  config.log_level = ENV.fetch('RAILS_LOG_LEVEL', 'info')

  # Forzar logs a la consola de Render
  if ENV["RAILS_LOG_TO_STDOUT"].present? || true
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  config.action_controller.perform_caching = true
  config.active_support.report_deprecations = false
  config.i18n.fallbacks = true
end
