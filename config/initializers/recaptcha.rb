Recaptcha.configure do |config|

  config.site_key  = '6LcSYhEUAAAAAOrwZzo5IuoxVkNEI53v3v2yzEoy'
  config.secret_key = Rails.application.secrets.recaptcha_secret_key
end