# frozen_string_literal: true

Rails.application.routes.draw do
  defaults format: 'json' do
    root to: 'root#index'

    resources :system_info, only: [:show]

    resources :user_tests, except: %i[new edit]
    resources :trials, except: %i[new edit create]
    resources :test_groups, only: %i[index show]
    resources :metrics, only: %i[index show]
    resources :filters, only: %i[index show]

    post '/users/:user_id/assignments', to: 'assignments#create', as: 'user_assignments'

    resources :system_info, only: [:show]
  end
end
