Rails.application.routes.draw do
  resources :drinks, except: %i[show]
  resources :clients, except: %i[show]

  resources :orders, except: %i[show] do
    resources :positions, controller: "order_positions", except: %i[index show]
  end

  resources :settlements, except: %i[show] do
    resources :positions, controller: "settlement_positions", except: %i[index show]
  end

  resources :settlement_prices, except: %i[show destroy] do
    patch :deactivate, on: :member
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root "inventory#show"
end
