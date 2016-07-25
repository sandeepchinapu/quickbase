Rails.application.routes.draw do
  #resources :quickbase
  get 'quickbase/withholdings'
  get '/quickbase', to: 'quickbase#index', as: 'quickbase'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
