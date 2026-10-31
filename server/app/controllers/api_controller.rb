# Base controller for API endpoints
# All API controllers should inherit from this instead of ApplicationController
class ApiController < ActionController::API
    before_action :authenticate!

    private

    def authenticate!
        token = request.headers['Authorization']&.split(' ')&.last
        unless token == Rails.application.credentials.dig(:sensor_api, :bearer_token)
            render json: { error: 'Unauthorized' }, status: :unauthorized
        end
    end
end
