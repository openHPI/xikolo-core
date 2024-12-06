# frozen_string_literal: true

module Xikolo
  module V2
    class QuizAPI < Grape::API::Instance
      namespace 'questions' do
        mount Endpoint::ListSelftests
      end
    end
  end
end
