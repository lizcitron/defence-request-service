Rails.application.routes.draw do
  root "dashboards#show"

  resource :dashboard, only: [:show]
  get "/refresh_dashboard", to: "dashboards#refresh_dashboard"

  get "/auth/:provider/callback", to: "sessions#create"

  resources :defence_requests, except: [:index] do
    collection do
      post "solicitors_search"
    end
    member do
      get "close"
      patch "close" => "defence_requests#feedback", as: "close_feedback"
      get "abort"
      patch "abort" => "defence_requests#reason_aborted", as: "reason_aborted"
      post "resend_details"
      patch "solicitor_time_of_arrival" => "defence_requests#solicitor_time_of_arrival", as: "solicitor_time_of_arrival"
    end
  end

  resource :transition_defence_request, only: [:create]

  get "/status" => "status#index"
  get "/help", controller: :static, action: :help, as: :help
  get "/maintenance", controller: :static, action: :maintenance, as: :maintenance
  get "/cookies", controller: :static, action: :cookies, as: :cookies
  get "/accessibility", controller: :static, action: :accessibility, as: :accessibility
  get "/terms", controller: :static, action: :terms, as: :terms
  get "/expired", controller: :static, action: :expired, as: :expired
end
