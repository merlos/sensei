class ApplicationController < ActionController::Base
    # Allow browser versions that support webp images, web push, badges, import maps, CSS nesting, and CSS :has
    allow_browser versions: :modern
    
    before_action :authenticate_web_user!
    
    private
    
    def authenticate_web_user!
        # Skip authentication in development for convenience
        return if Rails.env.development?
        
        authenticate_or_request_with_http_basic("Sensei Dashboard") do |username, password|
            expected_username = Rails.application.credentials.dig(:sensor_api, :dashboard_username) || "sensei"
            expected_password = Rails.application.credentials.dig(:sensor_api, :dashboard_password) || Rails.application.credentials.dig(:sensor_api, :bearer_token)
            
            username == expected_username && password == expected_password
        end
    end
end
