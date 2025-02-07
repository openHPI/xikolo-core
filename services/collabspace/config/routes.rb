# frozen_string_literal: true

Rails.application.routes.draw do
  defaults format: :json do
    resources :learning_rooms, controller: 'collab_spaces', except: %i[new edit]
    resources :collab_spaces, except: %i[new edit] do
      resources :files, only: %i[index create]
    end
    resources :memberships, only: %i[index create update destroy]
    resources :files, only: %i[show destroy]
    resources :calendar_events

    resources :system_info, only: %i[show]
    root to: 'root#index'
  end
end
