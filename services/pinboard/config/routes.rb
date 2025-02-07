# frozen_string_literal: true

Rails.application.routes.draw do
  defaults format: :json do
    resources :comments, except: %i[new edit]
    resources :answers, except: %i[new edit]
    resources :questions, except: %i[new edit]
    resources :votes, except: %i[new edit]
    resources :topics, only: %i[index show create]
    resources :posts, only: %i[show destroy] do
      resources :user_votes, only: %i[update]
    end
    resources :tags, only: %i[index show create]
    resources :explicit_tags, controller: 'tags', type: 'ExplicitTag', only: %i[index show create]
    resources :implicit_tags, controller: 'tags', type: 'ImplicitTag', only: %i[index show create]
    resources :subscriptions, except: %i[new edit]
    get '/subscriptions/:user_id/:question_id', to: 'subscriptions#show'
    resources :statistics, only: %i[index show]
    resources :abuse_reports, only: %i[index show create]
    get '/user_statistics/:user_id', to: 'user_statistics#show'

    resources :system_info, only: %i[show]
    root to: 'application#index'
  end
end
