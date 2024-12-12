# frozen_string_literal: true

Rails.application.routes.draw do
  defaults format: :json do
    resources :events, only: %i[index create]
    resource :mail_log_stats, only: [:show] # singleton!

    resources :system_info, only: [:show]
    root to: 'root#index'
  end
end
