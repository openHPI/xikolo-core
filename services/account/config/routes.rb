# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
Xikolo::Account::Application.routes.draw do
  scope module: 'api', defaults: {format: :json} do
    resources :users, except: %i[new edit] do
      resource :ban, only: :create
      resource :preferences, only: %i[show update]
      resource :profile, only: %i[update show]
      resources :sessions, only: [:index]
      resources :emails, except: %i[new edit] do
        delete 'suspension', to: 'email_suspensions#destroy'
      end
      put 'emails' => 'emails#replace'

      resources :permissions, only: [:index]

      resources :consents, only: %i[index show create destroy]
      patch  'consents' => 'consents#merge'

      get    'flippers' => 'features#index'
      get    'features' => 'features#index'
      patch  'features' => 'features#update'
      delete 'features' => 'features#destroy'
    end

    resources :sessions, only: %i[create show destroy] do
      resource :masquerade, only: %i[create destroy]
    end

    resources :tokens, only: %i[index show create]
    resources :authorizations, except: %i[new edit]
    resources :password_resets, only: %i[create show update]
    resources :policies, only: %i[index show create update]
    resources :groups, only: %i[index create show update destroy],
      format: false,
      constraints: {id: /[\w.-]+/} do
      resources :members, only: %i[index], controller: 'group_members'

      get    'memberships' => 'memberships#index'

      get    'features'    => 'features#index'
      patch  'features'    => 'features#update'
      delete 'features'    => 'features#destroy'

      get    'grants'      => 'groups#grants'
      get    'stats'       => 'group_stats#show'
      get    'profile_field_stats/:id', to: 'profile_field_stats#show', as: 'profile_field_stats'
    end

    resources :memberships, only: %i[create show destroy]
    delete 'memberships' => 'memberships#delete'

    resources :contexts, only: %i[create show index]
    resources :roles, only: %i[index create show update],
      format: false,
      constraints: {id: /[\w.-]+/}

    resources :grants, only: %i[index create show destroy]
    resources :treatments, only: %i[index create show update]

    resource :statistic, only: [:show]

    resources :emails, only: %i[show], constraints: {id: %r{[^/]+}}

    post 'emails/:address/suspend',
      as: 'email_suspension',
      to: 'email_suspensions#create',
      constraints: {address: %r{[^/]+}}

    resources :system_info, only: [:show]
    root to: 'root#index'
  end
end
# rubocop:enable Metrics/BlockLength
