# frozen_string_literal: true

Rails.application.routes.draw do
  mount QuizService::Engine => '/'
end
