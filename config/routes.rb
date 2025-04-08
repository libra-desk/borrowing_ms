Rails.application.routes.draw do
  resources :borrowings, only: [:index, :create] do 
    member do
      post :return
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
