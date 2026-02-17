Rails.application.routes.draw do
  devise_for :users, path: "secure"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  get "/home", to: "pages#home"
  get "/about", to: "pages#about"

  # Defines the root path route ("/")
  root "pages#home"
end
