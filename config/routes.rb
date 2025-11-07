# frozen_string_literal: true

Rails.application.routes.draw do
  resources :reports, only: %i[index create destroy], module: 'admin'

  resources :documents, controller: 'admin/documents' do
    resources :localizations, controller: 'admin/document_localizations', except: %i[show index]
  end

  post 'cookie_consent', to: 'cookie_consent#create'

  def pinboard_routes
    resources :pinboard, only: [:index]
    resources :question, only: %i[show create edit update destroy] do
      resources :pinboard_comment, only: %i[create update edit destroy] do
        member do
          post :abuse_report
          post :block
          post :unblock
        end
      end
      member do
        post :upvote
        post :accept_answer
        post :close
        post :reopen
        post :abuse_report
        post :block
        post :unblock
      end
    end
    resources :answer, only: %i[create update edit destroy] do
      resources :pinboard_comment, only: %i[create update edit destroy] do
        member do
          post :abuse_report
          post :block
          post :unblock
        end
      end
      member do
        post :upvote
        post :downvote
        post :abuse_report
        post :block
        post :unblock
      end
    end
  end

  # Authentication and Registration
  scope module: :account do
    resources :sessions, only: %i[new create]
    delete '/session/logout', to: 'sessions#destroy', as: :logout

    # These routes are actually intercepted by the omniauth middleware, sessions#new is not called
    get '/auth/:provider', to: 'sessions#new', as: :auth
    match '/auth/:provider/callback', to: 'sessions#authorization_callback',
      via: %i[get post], as: :auth_callback

    post 'sessions/new', to: 'sessions#new', as: :login
    resource :account, only: %i[new create] do
      resources :password_resets, only: %i[new show create update], as: :reset, path: :reset
      resources :confirmations, only: %i[show new create update], path: :confirm
      get 'policies', to: 'policies#show'
      put 'policies', to: 'policies#update'
      put 'consents', to: 'consents#update'
      get 'verify', to: 'accounts#verify'
    end

    get 'accounts/connect', to: 'connect#new', as: :connect_accounts

    resources :treatments, only: [:index]
    post 'treatments', to: 'treatments#consent', as: :consent_treatments

    scope path: :dashboard do
      get 'profile/edit', to: 'profiles#edit'
      patch 'profile', to: 'profiles#update'
      get 'profile/edit_avatar', to: 'profiles#edit_avatar'
      get 'profile/edit_email', to: 'profiles#edit_email'
      post 'profile/edit_email', to: 'profiles#update_email'
      get 'profile', to: 'profiles#show', as: :dashboard_profile
      post 'profile', to: 'profiles#update'
      scope path: :profile do
        delete 'emails/:id', to: 'profiles#delete_email', as: :delete_email
        patch 'change_primary_email/:id', to: 'profiles#change_primary_email', as: :change_primary_email
        patch 'visual', to: 'profiles#update_visual', as: :dashboard_profile_visual
        post 'password', to: 'profiles#change_my_password', as: :change_my_password
        delete 'auth/:id', to: 'profiles#delete_authorization', as: :auth_delete
        get 'unsuspend_primary_email', to: 'profiles#unsuspend_primary_email', as: :unsuspend_primary_email
      end
    end

    resource :preferences, only: %i[update show]
  end

  resources :videos, only: %i[index destroy], module: 'admin'
  resources :subtitles, only: %i[show destroy]

  resources :playlists, only: %i[show], module: 'video'

  resources :streams, only: [], module: 'stream' do
    resource :download, path: 'downloads/:quality', only: :show
    resource :sync, only: :create
  end

  # Certificates
  get '/certificate/render', to: 'course/certificates#render_certificate', as: :certificate_render, module: 'course'
  get '/verify/:id', to: 'course/certificates#verify', as: :certificate_verification, module: 'course'

  # Open Badges
  namespace :openbadges, module: :open_badges do
    get 'issuer', to: 'open_badges#issuer'
    get 'public_key', to: 'open_badges#public_key'
    get 'revocation_list', to: 'open_badges#revocation_list'

    scope path: :v2, module: :v2 do
      get 'issuer', to: 'open_badges#issuer', as: :issuer_v2
      get 'public_key', to: 'open_badges#public_key', as: :public_key_v2
      get 'revocation_list', to: 'open_badges#revocation_list', as: :revocation_list_v2
    end
  end

  resources :users, only: %i[index create new], module: 'admin' do
    resource :masquerade, only: %i[create destroy]
    resource :manual_confirmations, only: :create
    resource :bans, only: :create
  end
  resources :users, only: %i[show destroy]

  resources :teachers, except: :destroy, module: 'admin'
  resources :permissions, only: [:index], module: 'admin'
  resources :vouchers, only: %i[index create], module: 'admin'
  get '/vouchers/stats', to: 'admin/vouchers#stats', as: :vouchers_stats
  get '/vouchers/query', to: 'admin/vouchers#query', as: :vouchers_query
  resources :groups, only: [], module: 'admin' do
    resources :members, only: %i[create destroy], controller: 'permissions'
  end
  get '/admin/dashboard', to: 'admin/dashboard#show', as: :admin_dashboard, module: 'admin'
  post '/users/:id/change_user_password', to: 'users#change_user_password'
  resources :feeds, only: [:index]
  get '/feeds/courses', to: 'feeds#courses', as: :courses_feed, defaults: {format: 'json'}
  post '/courses/:id/clone', to: 'admin/courses#clone', as: :course_clone, module: 'admin'
  post '/courses/:id/generate_ranking', to: 'admin/course_management#generate_ranking', as: :generate_ranking_course
  get '/admin/courses(/:category)', to: 'admin/courses#index', as: :admin_courses
  resources :courses, only: %i[create update new edit destroy], module: 'admin'
  namespace :admin do
    scope module: :ajax do
      get 'platform_statistics/learners_and_enrollments', to: 'platform_statistics#learners_and_enrollments'
      get 'platform_statistics/activity', to: 'platform_statistics#activity'
      get 'platform_statistics/certificates', to: 'platform_statistics#certificates'

      get 'detail_statistics/countries', to: 'detail_statistics#countries'
      get 'detail_statistics/cities', to: 'detail_statistics#cities'
      get 'detail_statistics/top_item_types', to: 'detail_statistics#top_item_types'
      get 'detail_statistics/videos', to: 'detail_statistics#videos'
      get 'detail_statistics/most_active', to: 'detail_statistics#most_active'
      get 'dashboard_statistics/age_distribution', to: 'dashboard_statistics#age_distribution'
      get 'dashboard_statistics/client_usage', to: 'dashboard_statistics#client_usage'

      resources :streams, only: :index
      get '/find_courses', to: 'courses#index', constraints: ->(r) { r.xhr? }
      get '/find_users', to: 'users#index', constraints: ->(r) { r.xhr? }
      get '/find_classifiers', to: 'classifiers#index'
    end
    resources :polls, except: %i[show] do
      resources :options, only: %i[create destroy], controller: 'poll_options'
    end
  end
  get 'polls/next', to: 'polls#next', as: :next_poll
  get 'polls/archive', to: 'polls#archive', as: :polls_archive
  post 'polls/:id/vote', to: 'polls#vote', as: :vote_poll

  scope path: 'admin/statistics', module: 'admin', as: :admin_statistics do
    get 'news', to: 'statistics#news', as: :news
  end
  scope '/courses/:course_id/statistics', module: 'course/admin', as: :course_statistics do
    get 'activity', to: 'statistics#activity', as: :activity
    get 'geo', to: 'statistics#geo', as: :geo
    get 'news', to: 'statistics#news', as: :news
    get 'pinboard', to: 'statistics#pinboard', as: :pinboard
    get 'social', to: 'statistics#social', as: :social
    get 'referrer', to: 'statistics#referrer', as: :referrer
    get 'item_visits', to: 'statistics#item_visits', as: :item_visits
    get 'quiz', to: 'statistics#quiz', as: :quiz
    get 'item_details', to: 'statistics#item_details', as: :item_details
    get 'videos', to: 'statistics#videos', as: :videos
    get 'downloads', to: 'statistics#downloads', as: :downloads
    get 'rich_texts', to: 'statistics#rich_texts', as: :rich_texts
  end

  resources :channels, only: %i[create update new edit destroy], module: 'admin'
  resources :channels, only: %i[show], module: 'home'
  namespace :admin do
    resources :channels, only: %i[index]
    get '/channels/order', to: 'channels_order#index'
    post '/channels/order', to: 'channels_order#update'
  end

  resources :courses, only: %i[index], module: 'home'
  resources :courses, only: %i[create update new edit], module: 'admin'
  resources :courses, only: %i[show], module: 'course' do
    resources :free_reactivations, only: [:create]
  end
  resources :courses, only: [] do
    get 'launch(/:auth)', controller: 'course/launch', to: 'course/launch#launch', as: 'launch'
    get 'certificates', to: 'course/certificates#index', as: :certificates
    get 'certificate', to: 'course/certificates#show', as: :certificate, module: 'course'

    # Open Badges
    scope module: :open_badges do
      get 'assertion/:id', to: 'open_badges#assertion', as: :openbadges_assertion
      get 'badge', to: 'open_badges#badge_class', as: :openbadges_class

      namespace :openbadges, path: 'openbadges/v2', module: :v2 do
        get 'assertion/:id', to: 'open_badges#assertion', as: :assertion_v2
        get 'class', to: 'open_badges#badge_class', as: :class_v2
      end
    end

    # Make course announcements available as /courses/:course_id/announcements
    resources :announcements, except: %i[show], module: 'course'
    resources :lti_providers, except: %i[edit new show]

    get 'book/:product', to: 'course/voucher_redemptions#new', as: 'redeem_voucher'
    post 'book/:product', to: 'course/voucher_redemptions#create'

    resources :abuse_reports, only: [:index], module: 'course/admin'

    # Course permissions
    resources :permissions, only: [:index], module: 'course/admin'
    resources :groups, only: [], module: 'course/admin' do
      resources :members, only: %i[create destroy], controller: 'permissions'
    end
    resource :visual, only: %i[edit update], module: 'course/admin'
    resource :metadata, only: %i[show edit update destroy], module: 'course/admin'
    resources :offers, only: %i[index create update new edit destroy], module: 'course/admin'
    resources :certificate_templates, only: %i[index create update new edit destroy], module: 'course/admin' do
      member do
        get :preview, action: :preview_certificate
      end
    end
    resources :open_badge_templates, only: %i[index create update new edit destroy], module: 'course/admin'

    resource :recalculations, only: %i[create], module: 'course/admin/learning_evaluation'

    resource :progress, only: [:show], module: 'course'

    resources :items, only: %i[show edit] do
      resources :quiz_submission, only: %i[new show create]
      resources :quiz_submission_snapshot, only: [:create]
      resources :topics, only: [:create], module: 'course/ajax'
    end

    resources :sections, except: %i[new edit] do
      # resources :pinboard, only: [ :index ]
      pinboard_routes
      member do
        post :move
        post :choose_alternative_section
      end
      resources :items, except: [:index], as: :items do
        member do
          post :move
        end
        resources :quiz_questions, except: %i[index new show], as: :quiz_questions do
          member do
            post :move
          end
          resources :quiz_answers, except: %i[index show], as: :quiz_answers do
            member do
              post :move
            end
          end
        end
        resource :time_effort, only: %i[show update destroy], controller: 'item_time_effort', module: 'course/admin'
      end
    end
    pinboard_routes
  end

  scope '/courses/:course_id/items/:id' do
    get '/lti', to: 'items#show', as: :course_item_lti, defaults: {lti: true}
    get '/tool_launch', to: 'lti#tool_launch', as: :tool_launch_course_item
    post '/tool_grading', to: 'lti#tool_grading', as: :tool_grading_course_item, defaults: {format: 'xml'}
    get '/tool_return', to: 'lti#tool_return', as: :tool_return_course_item, defaults: {format: 'xml'}
  end
  # Legacy item routes:
  scope '/courses/:course_id/sections/:section_id/items/:id' do
    get '/tool_launch', to: 'lti#tool_launch', as: nil
    post '/tool_grading', to: 'lti#tool_grading', as: nil, defaults: {format: 'xml'}
    get '/tool_return', to: 'lti#tool_return', as: nil, defaults: {format: 'xml'}
  end

  scope module: :course do
    resources :enrollments, only: %i[create destroy] do
      member do
        post '/completion', to: 'enrollments/completion#create', as: :complete
      end
    end
    # TODO: refactor ugly hack to allow enrollments after redirect to login
    get '/enrollments', to: 'enrollments#create', as: 'create_enrollment'
  end

  # Legacy course route:
  get '/course/:id', to: 'course/courses#show'

  get '/pinboard_tags', to: 'pinboard#tags'
  delete '/tag/:id', to: 'pinboard#destroy', as: :tag_delete

  get '/helpdesk', to: 'helpdesk#show'
  post '/helpdesk', to: 'helpdesk#send_helpdesk'

  get '/dashboard', to: 'dashboard#dashboard'
  get '/dashboard/achievements', to: 'dashboard#achievements'
  get '/dashboard/documents', to: 'dashboard#documents'

  post 'courses/:course_id/add_attempt', to: 'course/admin/quiz_submissions#add_attempt', as: :add_attempt
  post 'courses/:course_id/add_fudge_points', to: 'course/admin/quiz_submissions#add_fudge_points', as: :add_fudge_points
  get '/courses/:id/dashboard', to: 'course/admin/dashboard#show', as: :course_dashboard
  get '/courses/:id/statistic', to: 'admin/course_management#statistic', as: :course_statistic
  get '/courses/:id/documents', to: 'course/documents#index', as: :course_documents
  get '/courses/:id/submission_statistics', to: 'admin/course_management#submission_statistics', as: :course_submission_statistics
  get '/courses/:course_id/items/:item_id/stats', to: 'course/admin/item_stats#show', as: :course_item_statistics
  get '/courses/:course_id/enrollments', to: 'course/admin/enrollments#index', as: :course_enrollments
  post '/courses/:course_id/enrollments', to: 'course/admin/enrollments#create', as: :teacher_create_enrollment
  delete '/courses/:course_id/enrollments/:user_id', to: 'course/admin/enrollments#destroy', as: :teacher_destroy_enrollment
  get '/courses/:id/submissions', to: 'admin/course_management#submissions', as: :course_submissions
  post 'courses/:id/convert_submission', to: 'admin/course_management#convert_submission', as: :convert_submission
  get '/courses/:id/resume', to: 'course/courses#resume', as: :course_resume
  post '/courses/:id/preview_quizzes', to: 'admin/course_management#preview_quizzes', as: :preview_quizzes
  post '/courses/:id/import_quizzes', to: 'admin/course_management#import_quizzes', as: :import_quizzes
  post '/courses/:id/import_quizzes_by_service', to: 'admin/course_management#import_quizzes_by_service', as: :import_quizzes_by_service
  get '/news', to: 'home/announcements#index', as: 'news_index'
  resources :announcements, path: 'news', only: %i[new create edit update destroy]
  get '/news/:id/', to: 'home/announcements#index' # as we dont have a index route yet
  get '/courses/:course_id/announcements/:id', to: 'course/announcements#index'
  get '/courses/:course_id/overview', to: 'course/syllabus#show', as: :course_overview

  # The web manifest (for home screen installation on mobile devices)
  get '/web_manifest.json', to: 'web_manifest#show'

  # ChromeCast Styled Media Receiver
  get '/chromecast.css', to: 'chromecast#stylesheet', defaults: {format: 'css'}

  scope '.well-known', module: 'well_known' do
    get 'assetlinks.json', to: 'app_links#android'
    get 'apple-app-site-association', to: 'app_links#ios'
    get ':filename', to: 'files#show', constraints: {filename: %r{[^/]+}}
  end

  get '/pages/:id', to: 'home/pages#show', as: 'page'
  resources :pages, only: %i[edit edit update]

  get '/files/logo', to: 'files#logo'
  get '/favicon.ico', to: 'files#favicon'
  get '/avatar/:id(/size/:size)', to: 'files#avatar', as: :avatar

  post '/subscriptions/toggle_subscription/:question_id', to: 'subscriptions#toggle_subscription', as: :toggle_subscription
  post '/subscriptions/unsubscribe/:question_id', to: 'user/subscriptions#destroy', as: :unsubscribe
  get '/subscriptions/subscription_count_text', to: 'subscriptions#subscription_count_text', as: :subscription_count_text
  resources :course_subscriptions, only: %i[create destroy]

  resource :notification_user_disables, path: '/notification_user_settings/disable', only: %i[show create]

  get '/learn', to: 'learning_mode#index'
  get '/learn/review', to: 'learning_mode#review'

  get 'ical', to: 'ical#index'

  # Private API endpoints used by the frontend only. Must shadow the
  # deprecated public API below.
  post 'api/tracking-events', to: 'api/tracking_events#create'

  # mount Rack based API app
  mount Xikolo::API => '/api'

  get 'app/quiz-recap', to: 'quiz_recap#show'

  namespace :admin do
    resources :clusters, only: %i[index show edit update] do
      resources :classifiers, only: %i[new create edit update destroy] do
        get '/courses/order', to: 'classifier/courses_order#index'
        post '/courses/order', to: 'classifier/courses_order#update'
      end
      get '/classifiers/order', to: 'cluster/classifiers_order#index'
      post '/classifiers/order', to: 'cluster/classifiers_order#update'
    end
    resources :lti_providers, except: %i[show]
    resources :announcements, except: %i[show destroy] do
      member do
        resource :email, as: 'announcement_email', controller: 'announcement_emails', only: %i[show new create]
      end
    end
    namespace :announcement do
      resources :recipients, only: %i[index]
    end
    resources :video_providers, except: %i[show] do
      member do
        resource :sync, only: %i[create], controller: 'video_provider_sync', as: :sync_video_provider
      end
    end
  end

  # all routes for go, the shortcut for redirects etc.
  scope 'go', module: :home, as: 'go' do
    get '/items/:id', to: 'go#item'
    get '/items/:id/pinboard', to: 'go#pinboard'
    get '/link', to: 'go#redirect'
    get '/launch/:course_id(/:auth)', to: 'go#course'
    get '/survey/:id', to: 'go#survey'
  end

  # Public API for customers portal
  scope 'portalapi-beta', module: :portal_api, as: 'portal' do
    resources :courses, only: %i[index show]
    resources :users, only: %i[update destroy]
    resources :enrollments, only: %i[index create]
  end

  scope 'bridges', module: :bridges, as: 'bridges' do
    # Internal Bridge Transpipe API
    scope 'transpipe', module: :transpipe, as: 'transpipe' do
      resources :courses, only: %i[index show]
      resources :videos, only: :show do
        member do
          get 'subtitles/:lang', to: 'subtitles#show'
          patch 'subtitles/:lang', to: 'subtitles#update'
        end
      end
    end

    scope 'lanalytics', module: :lanalytics, as: 'lanalytics', defaults: {format: 'json'} do
      get '/', to: 'root#index'

      scope 'courses/:course_id', as: 'course' do
        resource :ticket_stats, controller: 'course_ticket_stats', only: %i[show]
        resource :open_badge_stats, controller: 'course_open_badge_stats', only: %i[show]
      end

      scope 'videos/:video_id' do
        resource :video_stats, controller: 'video_stats', only: %i[show]
      end
    end

    scope 'moochub', module: :mooc_hub, as: 'moochub' do
      resources :courses, only: %i[index]
    end

    scope 'chatbot', module: :chatbot, as: 'chatbot' do
      post 'authenticate', to: 'authentications#create'
      get 'my_courses', to: 'my_courses#index'
      post 'my_courses/:id', to: 'my_courses#create'
      delete 'my_courses/:id', to: 'my_courses#destroy'
      get 'my_courses/:id/achievements', to: 'my_course_achievements#show'
      get 'courses', to: 'courses#index'
      get 'user', to: 'users#show'
      get 'my_quizzes', to: 'my_quizzes#index'
    end

    scope 'shop', module: :shop, as: 'shop', defaults: {format: 'json'} do
      resources :vouchers, only: %i[index create]
    end
  end

  resources :ping, only: %i[index]
  root to: 'home/home#index'

  if Rails.env.development?
    mount Lookbook::Engine, at: '/rails/components'
  end

  if Rails.env.test? || Rails.env.integration?
    get '/__session__', to: 'account/test#show'
    post '/__session__', to: 'account/test#update'
  end
end
