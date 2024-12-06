# frozen_string_literal: true

Rails.application.routes.draw do
  defaults format: 'json' do
    resources :quizzes, except: %i[new edit] do
      member do
        post :clone
      end
    end

    resources :questions, except: %i[new edit]

    # Create routes to the questions controller for every question type
    {
      multiple_answer_questions: 'MultipleAnswerQuestion',
      multiple_choice_questions: 'MultipleChoiceQuestion',
      free_text_questions: 'FreeTextQuestion',
      essay_questions: 'EssayQuestion',
    }.each do |path, klass|
      defaults type: klass do
        get path, to: 'questions#index'
        post path, to: 'questions#create'
      end
      resources path, except: %i[index create new edit], controller: 'questions'
    end

    resources :answers, except: %i[new edit]
    resources :text_answers, except: %i[new edit]
    resources :free_text_answers, except: %i[new edit]

    resources :quiz_submissions, except: %i[new edit]
    resources :quiz_submission_questions, only: [:index]
    resources :quiz_submission_free_text_answers, only: [:index]
    resources :quiz_submission_answers, only: [:index]
    resources :quiz_submission_selectable_answers, only: [:index]
    resources :quiz_submission_snapshots, except: [:new]
    resource :user_quiz_attempts, only: %i[show create]

    get '/submission_statistics/:id', to: 'submission_statistics#show', as: :submission_statistic
    get '/submission_question_statistics/:id', to: 'submission_question_statistics#show', as: :submission_question_statistic

    # deprecated
    resources :quiz_submission_statistics, only: [:show], controller: :submission_statistics

    resources :system_info, only: [:show]

    post '/quizzes/preview', to: 'quizzes#preview', as: 'preview'
    root to: 'application#index'
  end
end
