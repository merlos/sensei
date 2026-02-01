# Be sure to restart your server when you modify this file.

# Enable serving static files from the /public folder
Rails.application.config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present? || Rails.env.production?
