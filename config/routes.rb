Rails.application.routes.draw do
  resources :drinks, except: %i[show destroy]

  resources :clients, except: %i[destroy] do
    member do
      patch :suspend
      patch :reinstate
    end
    resources :payments, only: %i[new create]
  end

  namespace :external do
    resources :client, param: :access_uuid, only: %i[show] do
      resources :monthly_reports, only: %i[show]
    end
    resources :settlement_tracking, only: %i[show]
  end

  namespace :api do
    resources :clients, only: %i[index]
    resources :drinks, only: %i[index]
    resources :monthly_reports, only: %i[index] do
      member do
        post :complete
        post :reopen
      end
    end

    resources :settlements, only: %i[index show create update] do
      member do
        post :complete
        post :send_email
      end

      resources :positions, controller: "settlement_positions", only: %i[create update destroy]
    end
  end

  resources :payments, only: %i[index]

  resources :orders, except: %i[show destroy] do
    resources :positions, controller: "order_positions", except: %i[index show destroy]
  end

  resources :monthly_reports, except: %i[show destroy] do
    member do
      patch :complete
      patch :reopen
      patch :complete_settlements
      patch :schedule_settlement_emails
    end
  end

  resources :settlements, except: %i[show] do
    collection do
      get "filtered/:client_id", to: "settlements#filtered", as: :filtered
    end

    member do
      patch :complete
      patch :schedule_email
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
