# frozen_string_literal: true

Rails.application.routes.draw do
  resources :system_info, only: [:show]
  resources :announcements, only: %i[index create show] do
    resource :email, only: [:create]
    resources :messages, only: %i[create]
    put '/user_visits/:user_id', to: 'visits#create', as: :user_visit
    patch '/user_visits/:user_id', to: 'visits#create'
  end
  resources :messages, only: %i[show]
  resources :posts, only: %i[index]

  resources :visits, only: [:create]

  # @deprecated - Remove once data model and usages have been cleaned up
  resources :news, only: %i[index show create update destroy]

  root to: 'root#index'
end
