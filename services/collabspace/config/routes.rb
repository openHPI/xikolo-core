# frozen_string_literal: true

Rails.application.routes.draw do
  defaults format: 'json' do
    resources :learning_rooms, controller: 'collab_spaces', except: %i[new edit]
    resources :collab_spaces, except: %i[new edit] do
      resources :files, only: %i[index create]
    end
    resources :memberships, except: %i[new edit]
    resources :files, only: %i[show destroy]
    resources :system_info, only: [:show]
    resources :calendar_events

    root to: 'root#index'
  end
end
