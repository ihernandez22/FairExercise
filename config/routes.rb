Rails.application.routes.draw do
  root "application#index"
  resources :credit_cards, only: [:index, :new, :create, :show] do
    resources :transactions, only: [:new, :create]
  end
  get "credit_cards/:id/close_payment_period", to: "credit_cards#close_payment_period"
end
