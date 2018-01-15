Rails.application.routes.draw do
  resources :credit_cards, only: [:show, :create] do
    resources :transactions, only: [:create]
  end
  post "credit_cards/:id/close_payment_period", to: "credit_cards#close_payment_period"
end
