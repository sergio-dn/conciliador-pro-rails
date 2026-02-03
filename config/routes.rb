Rails.application.routes.draw do
  root 'reconciliations#new'

  resources :reconciliations, only: [:new, :create, :show] do
    collection do
      post :upload_bank
      post :upload_sales
      delete :reset
    end
    member do
      get :tab
    end
  end

  resources :exports, only: [:create]
end
