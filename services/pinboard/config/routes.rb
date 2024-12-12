# frozen_string_literal: true

Rails.application.routes.draw do
  defaults format: :json do
    resources :comments, except: %i[new edit]
    resources :answers, except: %i[new edit]
    resources :questions, except: %i[new edit]
    resources :votes, except: %i[new edit]
    resources :topics, only: %i[index create show]
    resources :posts, only: %i[show destroy] do
      resources :user_votes, only: [:update]
    end
    resources :tags, except: %i[new edit]
    resources :explicit_tags, controller: 'tags', type: 'ExplicitTag', except: %i[new edit]
    resources :implicit_tags, controller: 'tags', type: 'ImplicitTag', except: %i[new edit]
    resources :subscriptions, except: %i[new edit]
    get '/subscriptions/:user_id/:question_id', to: 'subscriptions#show'
    resources :statistics, only: %i[index show]
    resources :abuse_reports, only: %i[index show create]
    get '/user_statistics/:user_id', to: 'user_statistics#show'

    resources :system_info, only: [:show]
    root to: 'application#index'
  end
end
