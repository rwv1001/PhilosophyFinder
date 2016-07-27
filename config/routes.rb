Rails.application.routes.draw do
  resources :domain_crawlers
  resources :search_queries
  resources :group_names
  resources :search_results
  resources :regex_templates
  get 'password_resets/new'

  get 'signup', to: 'users#new', as: 'signup'
  get 'login', to: 'sessions#new', as: 'login'
  get 'logout', to: 'sessions#destroy', as: 'logout'

  get "/set_header" => 'domain_crawlers#set_header', as: 'set_header'

  get 'search', to: 'domain_crawlers#search', as: 'search'

  resources :users
  resources :sessions
  resources :password_resets


  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root 'users#index'
end
