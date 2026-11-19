# frozen_string_literal: true

Rails.application.routes.draw do
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
      resource :guardian_consent, only: %i[show update]
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

  resources :videos, only: %i[new index create destroy], module: 'admin' do
    member do
      post :retry
    end
  end
  resources :subtitles, only: %i[show destroy] do
    member do
      get 'download'
    end
  end

  resources :playlists, only: %i[show], module: 'video'

  resources :streams, only: [], module: 'stream' do
    resource :download, path: 'downloads/:quality', only: :show
    resource :sync, only: :create
  end

  # Certificates
  get '/certificate/render', to: 'course/certificates#render_certificate', as: :certificate_render, module: 'course'
  get '/verify/:id', to: 'course/certificates#verify', as: :certificate_verification, module: 'course'

  resources :users, only: %i[index], module: 'admin' do
    resource :masquerade, only: %i[create destroy]
    resource :manual_confirmations, only: :create
    resource :bans, only: %i[create destroy]
    resource :top_talents, only: %i[create destroy]
  end
  resources :users, only: %i[show destroy]

  resources :teachers, module: 'admin'
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
  post '/learn/:id/clone', to: 'admin/courses#clone', as: :course_clone, module: 'admin'
  post '/learn/:id/generate_ranking', to: 'admin/course_management#generate_ranking', as: :generate_ranking_course
  get '/admin/learn(/:category)', to: 'admin/courses#index', as: :admin_courses
  resources :courses, only: %i[create update new edit destroy], module: 'admin', path: 'learn'
  namespace :admin do
    scope module: :ajax do
      get 'dashboard_statistics/age_distribution', to: 'dashboard_statistics#age_distribution'

      resources :streams, only: :index
      get '/find_courses', to: 'courses#index', constraints: ->(r) { r.xhr? }
      get '/find_users', to: 'users#index', constraints: ->(r) { r.xhr? }
      get '/find_classifiers', to: 'classifiers#index'
    end
  end

  scope path: 'admin/statistics', module: 'admin', as: :admin_statistics do
    get 'news', to: 'statistics#news', as: :news
  end
  scope '/learn/:course_id/statistics', module: 'course/admin', as: :course_statistics do
    get 'news', to: 'statistics#news', as: :news
    get 'pinboard', to: 'statistics#pinboard', as: :pinboard
  end

  resources :channels, only: %i[create update new edit destroy], module: 'admin'
  resources :channels, only: %i[show], module: 'home'
  namespace :admin do
    resources :shorts, only: %i[index create update new edit destroy]
    resources :channels, only: %i[index]
    get '/channels/order', to: 'channels_order#index'
    post '/channels/order', to: 'channels_order#update'
  end

  # Fallback for old courses routes, redirect to learn
  get '/courses/*path', to: redirect('/learn/%{path}')
  get '/courses', to: redirect('/learn')

  get '/learn/:id/content/:blob_id/*path', to: 'cmi5_contents#show', as: :course_content, format: false

  resources :courses, only: %i[index], module: 'home', path: 'learn'
  resources :courses, only: %i[create update new edit], module: 'admin', path: 'learn'
  resources :courses, only: %i[show], module: 'course', path: 'learn' do
    get :teaser_signed_url, on: :member
  end

  resources :courses, only: [], path: 'learn' do
    get 'launch(/:auth)', controller: 'course/launch', to: 'course/launch#launch', as: 'launch'
    get 'certificate', to: 'course/certificates#show', as: :certificate, module: 'course'

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

    resource :recalculations, only: %i[create], module: 'course/admin/learning_evaluation'

    resource :progress, only: [:show], module: 'course' do
      get :bar
    end

    resources :items, only: %i[show edit] do
      member do
        get :signed_url
      end
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
        collection do
          get :new_exam
        end
        member do
          post :move
          get :edit_exam
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
      end
    end
    pinboard_routes
  end

  namespace :cmi5 do
    resources :tokens, only: [:create]

    # TinCan.js sends individual statements via PUT and batches via POST.
    match 'reportings/statements',
      to: 'reportings#create',
      via: %i[post put],
      as: :reportings_statements

    get 'reportings/activities', to: 'reportings#activity', as: :reportings_activities
    get 'reportings/agents/profile', to: 'reportings#agent_profile', as: :reportings_agents_profile

    # xAPI state management (AU calls retrieveState during initialization)
    get 'reportings/activities/state', to: 'state#show'
    put 'reportings/activities/state', to: 'state#update'
  end

  scope '/learn/:course_id/items/:id' do
    get '/lti', to: 'items#show', as: :course_item_lti, defaults: {lti: true}
    get '/tool_launch', to: 'lti#tool_launch', as: :tool_launch_course_item
    post '/tool_grading', to: 'lti#tool_grading', as: :tool_grading_course_item, defaults: {format: 'xml'}
    get '/tool_return', to: 'lti#tool_return', as: :tool_return_course_item, defaults: {format: 'xml'}
  end
  # Legacy item routes:
  scope '/learn/:course_id/sections/:section_id/items/:id' do
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

  post 'learn/:course_id/add_attempt', to: 'course/admin/quiz_submissions#add_attempt', as: :add_attempt
  post 'learn/:course_id/add_fudge_points', to: 'course/admin/quiz_submissions#add_fudge_points', as: :add_fudge_points
  get '/learn/:id/dashboard', to: 'course/admin/dashboard#show', as: :course_dashboard
  get '/learn/:course_id/items/:item_id/stats', to: 'course/admin/item_stats#show', as: :course_item_statistics
  get '/learn/:course_id/enrollments', to: 'course/admin/enrollments#index', as: :course_enrollments
  post '/learn/:course_id/enrollments', to: 'course/admin/enrollments#create', as: :teacher_create_enrollment
  delete '/learn/:course_id/enrollments/:user_id', to: 'course/admin/enrollments#destroy', as: :teacher_destroy_enrollment
  get '/learn/:id/submissions', to: 'admin/course_management#submissions', as: :course_submissions
  post 'learn/:id/convert_submission', to: 'admin/course_management#convert_submission', as: :convert_submission
  get '/learn/:id/resume', to: 'course/courses#resume', as: :course_resume
  post '/learn/:id/import_quizzes', to: 'admin/course_management#import_quizzes', as: :import_quizzes
  get '/news', to: 'home/announcements#index', as: 'news_index'
  resources :announcements, path: 'news', only: %i[new create edit update destroy]
  get '/news/:id/', to: 'home/announcements#index' # as we dont have a index route yet
  get '/courses/:course_id/announcements/:id', to: 'course/announcements#index'
  get '/learn/:course_id/overview', to: 'course/syllabus#show', as: :course_overview

  # The web manifest (for home screen installation on mobile devices)
  get '/web_manifest.json', to: 'web_manifest#show'

  # ChromeCast Styled Media Receiver
  get '/chromecast.css', to: 'chromecast#stylesheet', defaults: {format: 'css'}

  scope '.well-known', module: 'well_known' do
    get 'assetlinks.json', to: 'app_links#android'
    get 'apple-app-site-association', to: 'app_links#ios'
    get ':filename', to: 'files#show', constraints: {filename: %r{[^/]+}}
  end

  get '/about', to: 'home/about#show', as: 'about'

  get '/pages/:id', to: 'home/pages#show', as: 'page'
  resources :pages, only: %i[edit edit update]

  get '/files/logo', to: 'files#logo'
  get '/favicon.ico', to: 'files#favicon'
  get '/avatar/:id(/size/:size)', to: 'files#avatar', as: :avatar

  resources :shorts, only: [] do
    member do
      get :signed_url
    end
  end

  post '/subscriptions/toggle_subscription/:question_id', to: 'subscriptions#toggle_subscription', as: :toggle_subscription
  post '/subscriptions/unsubscribe/:question_id', to: 'user/subscriptions#destroy', as: :unsubscribe
  get '/subscriptions/subscription_count_text', to: 'subscriptions#subscription_count_text', as: :subscription_count_text
  resources :course_subscriptions, only: %i[create destroy]

  resource :notification_user_disables, path: '/notification_user_settings/disable', only: %i[show create]

  get 'ical', to: 'ical#index'

  get '/recap', to: 'quiz_recap#index'
  get '/recap/review', to: 'quiz_recap#review'
  get 'app/quiz-recap', to: 'quiz_recap#show'

  namespace :admin do
    resources :clusters, only: %i[index show edit update] do
      resources :classifiers, only: %i[new create edit update destroy] do
        get '/learn/order', to: 'classifier/courses_order#index'
        post '/learn/order', to: 'classifier/courses_order#update'
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

  scope 'bridges', module: :bridges, as: 'bridges' do
    scope 'moochub', module: :mooc_hub, as: 'moochub' do
      resources :courses, only: %i[index]
    end

    scope 'shop', module: :shop, as: 'shop', defaults: {format: 'json'} do
      resources :vouchers, only: %i[index create]
    end
  end

  resources :ping, only: %i[index]
  root to: 'home/home#index'

  constraints ServiceAuthorizationConstraint.new do
    mount AccountService::Engine => '/account_service'
    mount PinboardService::Engine => '/pinboard_service'
    mount NewsService::Engine => '/news_service'
    mount QuizService::Engine => '/quiz_service'
    mount CourseService::Engine => '/course_service'
    mount NotificationService::Engine => '/notification_service'
  end

  mount MissionControl::Jobs::Engine, at: '/jobs'

  if Rails.env.development?
    mount Lookbook::Engine, at: '/rails/components'
  end

  mount Coverband::Reporters::Web.new, at: '/coverage' if defined?(Coverband)
  mount MaintenanceTasks::Engine, at: '/maintenance_tasks'
end
