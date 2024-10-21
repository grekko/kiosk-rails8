Rails.application.routes.draw do
  resources :drinks, except: %i[show destroy]
  resources :clients, except: %i[show destroy]

  resources :orders, except: %i[show destroy] do
    resources :positions, controller: "order_positions", except: %i[index show destroy]
  end

  resources :settlements, except: %i[show] do
    member do
      patch :complete
      patch :mark_paid
    end

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
