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

  get "/display_group" => 'domain_crawlers#display_group', as: 'display_group'

  get "/delete_result" => 'domain_crawlers#delete_result', as: 'delete_result'

  get 'search', to: 'domain_crawlers#search', as: 'search'

  get 'group_action', to: 'domain_crawlers#group_action', as: 'group_action'

  post 'add_result', to:'domain_crawlers#add_result', as: 'add_result'
  post 'remove_group_result', to:'domain_crawlers#remove_group_result', as: 'remove_group_result'


  resources :users
  resources :sessions
  resources :password_resets


  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root 'users#index'
end
