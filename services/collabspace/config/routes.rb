# frozen_string_literal: true

Rails.application.routes.draw do
  defaults format: :json do
    resources :learning_rooms, controller: 'collab_spaces', except: %i[new edit]
    resources :collab_spaces, except: %i[new edit] do
      resources :files, only: %i[index create]
    end
    resources :memberships, except: %i[new edit]
    resources :files, only: %i[show destroy]
    resources :calendar_events

    resources :system_info, only: [:show]
    root to: 'root#index'
  end
end
