# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

Rails.application.config.assets.precompile =  ['*.js', '*.css', '*.css.erb']
Rails.application.config.assets.precompile += %w( favicon/apple-touch-icon.png )
Rails.application.config.assets.precompile += %w( favicon/apple-touch-icon-precomposed.png )
Rails.application.config.assets.precompile += %w( favicon/apple-touch-icon-57x57.png  )
Rails.application.config.assets.precompile += %w( favicon/apple-touch-icon-57x57-precomposed.png )
Rails.application.config.assets.precompile += %w( favicon/apple-touch-icon-60x60.png )
Rails.application.config.assets.precompile += %w( favicon/apple-touch-icon-60x60-precomposed.png )
Rails.application.config.assets.precompile += %w( favicon/apple-touch-icon-72x72.png )
Rails.application.config.assets.precompile += %w( favicon/apple-touch-icon-72x72-precomposed.png )
Rails.application.config.assets.precompile += %w( favicon/apple-touch-icon-76x76.png )
Rails.application.config.assets.precompile += %w( favicon/apple-touch-icon-76x76-precomposed.png )
Rails.application.config.assets.precompile += %w( favicon/apple-touch-icon-114x114.png )
Rails.application.config.assets.precompile += %w( favicon/apple-touch-icon-114x114-precomposed.png )
Rails.application.config.assets.precompile += %w( favicon/apple-touch-icon-120x120.png )
Rails.application.config.assets.precompile += %w( favicon/apple-touch-icon-120x120-precomposed.png )
Rails.application.config.assets.precompile += %w( favicon/apple-touch-icon-144x144.png )
Rails.application.config.assets.precompile += %w( favicon/apple-touch-icon-144x144-precomposed.png )
Rails.application.config.assets.precompile += %w( favicon/apple-touch-icon-152x152.png )
Rails.application.config.assets.precompile += %w( favicon/apple-touch-icon-152x152-precomposed.png )
Rails.application.config.assets.precompile += %w( favicon/favicon-32x32.png )
Rails.application.config.assets.precompile += %w( favicon/favicon-16x16.png )
Rails.application.config.assets.precompile += %w( favicon/manifest.json )
Rails.application.config.assets.precompile += %w( favicon/safari-pinned-tab.svg )
Rails.application.config.assets.precompile += %w( favicon/favicon.ico )
Rails.application.config.assets.precompile += %w( favicon/browserconfig.xml )