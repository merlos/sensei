Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Web UI Dashboard
  root "dashboard#index"
  get "dashboard", to: "dashboard#index", as: :dashboard
  get "dashboard/sensor/:code", to: "dashboard#sensor", as: :dashboard_sensor
  
  # AJAX endpoints for inline editing
  patch "dashboard/sensor/:code/update", to: "dashboard#update_sensor", as: :update_dashboard_sensor
  delete "dashboard/sensor/:code", to: "dashboard#delete_sensor", as: :delete_dashboard_sensor
  patch "dashboard/reading/:id", to: "dashboard#update_reading", as: :update_dashboard_reading
  delete "dashboard/reading/:id", to: "dashboard#destroy_reading", as: :destroy_dashboard_reading

  # ============================================
  # API Endpoints (require Bearer token auth)
  # ============================================
  
  # config/routes.rb
  post '/sensor_data', to: 'sensor_data#create'
  get '/sensors', to: 'sensors#index' 
  get '/sensor_data/:sensor_code', to: 'sensor_data#index'
  
  # Summary endpoints for aggregated sensor data
  get '/sensor_data/:sensor_code/daily', to: 'sensor_data#summary', defaults: { period: 'daily' }
  get '/sensor_data/:sensor_code/weekly', to: 'sensor_data#summary', defaults: { period: 'weekly' }
  get '/sensor_data/:sensor_code/monthly', to: 'sensor_data#summary', defaults: { period: 'monthly' }

  # Last period endpoints - returns raw data points
  get '/sensor_data/:sensor_code/last/day', to: 'sensor_data#last_period', defaults: { period: 'day' }
  get '/sensor_data/:sensor_code/last/week', to: 'sensor_data#last_period', defaults: { period: 'week' }
  get '/sensor_data/:sensor_code/last/month', to: 'sensor_data#last_period', defaults: { period: 'month' }
  get '/sensor_data/:sensor_code/last/year', to: 'sensor_data#last_period', defaults: { period: 'year' }
  get '/sensor_data/:sensor_code/last/all', to: 'sensor_data#last_period', defaults: { period: 'all' }

  # Daily summary for last period endpoints - returns daily aggregated summaries
  get '/sensor_data/:sensor_code/daily-last/day', to: 'sensor_data#daily_last_period', defaults: { period: 'day' }
  get '/sensor_data/:sensor_code/daily-last/week', to: 'sensor_data#daily_last_period', defaults: { period: 'week' }
  get '/sensor_data/:sensor_code/daily-last/month', to: 'sensor_data#daily_last_period', defaults: { period: 'month' }
  get '/sensor_data/:sensor_code/daily-last/year', to: 'sensor_data#daily_last_period', defaults: { period: 'year' }
  get '/sensor_data/:sensor_code/daily-last/all', to: 'sensor_data#daily_last_period', defaults: { period: 'all' }

end