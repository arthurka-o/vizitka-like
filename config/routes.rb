Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations',
    passwords: 'users/passwords'
  }
  as :publisher do
    post   '/users'        => 'registrations#create'
    post   '/users/sign_in'  => 'sessions#create'
    delete '/users/sign_out' => 'sessions#destroy'
  end
  
  resources :orders, only: :create
end
