# frozen_string_literal: true

Rails.application.routes.draw do
  defaults format: 'json' do
    resources :system_info, only: %i[show]
    resource :statistics, only: %i[show]

    resources :peer_assessments, except: %i[new edit] do
      resources :user_steps, only: %i[index]
      resources :files, only: %i[create destroy], controller: 'peer_assessment_files'
    end
    resources :submissions, except: %i[new edit destroy] do
      resources :files, only: %i[create destroy], controller: 'submission_files'
    end
    resources :shared_submissions, only: %i[index show]
    resources :reviews, except: %i[edit new create]
    resources :rubrics, except: %i[new edit]
    resources :rubric_options, except: %i[new edit]
    resources :participants, except: %i[new edit destroy]
    resources :groups, except: %i[new edit update destroy]
    resources :conflicts, except: %i[new edit]
    resources :grades, only: %i[index show update]
    resources :gallery_votes, except: %i[new edit]
    resources :notes, except: %i[new edit]

    resources :steps, only: %i[index show update create]
    resources :assignment_submissions, controller: 'steps', type: 'AssignmentSubmission', only: %i[index update create]
    resources :trainings, controller: 'steps', type: 'Training', only: %i[index update create]
    resources :peer_gradings, controller: 'steps', type: 'PeerGrading', only: %i[index update create]
    resources :results, controller: 'steps', type: 'Results', only: %i[index update create]
    resources :self_assessments, controller: 'steps', type: 'SelfAssessment', only: %i[index update create]

    root to: 'application#index'
  end
end
