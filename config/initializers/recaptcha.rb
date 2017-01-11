Recaptcha.configure do |config|

  config.site_key  = '6LctYhEUAAAAABREHkwI0351SIs4VDVg5y-oT2xV'
  config.secret_key = Rails.application.secrets.recaptcha_secret_key
end