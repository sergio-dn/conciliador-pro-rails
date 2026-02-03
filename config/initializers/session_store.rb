# Configure session store with larger cookie size for storing transaction data
Rails.application.config.session_store :cookie_store,
  key: '_reconciliacion_session',
  expire_after: 1.day
