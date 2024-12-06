# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
Rails.application.routes.draw do
  get '/items/current', to: 'items#current'
  resources :items, except: %i[new edit] do
    resources :users, only: [] do
      resource :visit, only: %i[create show]
      resource :grade, controller: :item_grade, only: :show
      resources :results, only: :create
    end
    resources :results, controller: :item_results, only: :index
    get '/statistics', to: 'item_statistics#show', as: :statistics
  end
  resources :results, only: %i[show update]
  resources :courses, except: %i[new edit] do
    resource :statistic, only: %i[show]
    resource :persist_ranking_task, only: :create
    resource :documents, only: %i[index create]
    get '/achievements', to: 'achievements#index'
    post '/learning_evaluation', to: 'learning_evaluation/recalculations#create'
    member do
      get '/prerequisite_status', to: 'prerequisite_status#index'
    end
  end

  resources :documents_tags, only: %i[index]
  resources :documents, only: %i[index show create update destroy] do
    resources :document_localizations, only: %i[index create]
  end
  resources :document_localizations, only: %i[index show update destroy]

  resources :channels

  resources :next_dates, only: :index

  resources :classifiers, only: %i[index show]
  resources :sections, except: %i[new edit]
  resources :section_choices, only: %i[create index]
  resources :enrollments, except: %i[new edit] do
    resources :reactivations, only: :create
  end

  resources :teachers, only: %i[index create show update]

  resources :richtexts, only: %i[show]

  resources :system_info, only: %i[show]

  resources :last_visits, only: %i[show], param: :course_id
  resources :progresses, only: %i[index]
  resource :stats, only: %i[show] # singleton!

  resources :repetition_suggestions, only: %i[index]

  get 'enrollment_stats', to: 'statistics#enrollment_stats', as: 'enrollment_stats'

  namespace :api do
    namespace :v2 do
      namespace :course do
        root to: 'application#index'
        resources :courses, only: %i[index show]
      end
    end
  end

  root to: 'root#index'
end
# rubocop:enable Metrics/BlockLength
