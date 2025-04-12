Rails.application.routes.draw do
  resources :borrowings, only: [ :index, :create ]
    # member do
    #   post :return_book
    # end
  
  post '/return', to: 'borrowings#return_book'
  post '/borrowed_books', to: 'borrowings#borrowed_books' 

  get "up" => "rails/health#show", as: :rails_health_check
end
