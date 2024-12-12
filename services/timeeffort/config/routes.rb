# frozen_string_literal: true

Rails.application.routes.draw do
  defaults format: :json do
    resources :items, only: %i[index create show] do
      put 'overwritten_time_effort', to: 'items#overwrite_time_effort'
      delete 'overwritten_time_effort', to: 'items#clear_overwritten_time_effort'
    end

    resources :system_info, only: %i[show]
    root 'root#index'
  end
end
