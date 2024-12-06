# frozen_string_literal: true

module Xikolo
  module V2
    class LearningInsightsAPI < Grape::API::Instance
      namespace 'learning_insights' do
        namespace 'progression' do
          namespace 'timebased_quiz_points' do
            desc 'Returns all user points timebased as time series grouped by hour and day of week'
            params do
              requires :course_id,  type: String, desc: 'The course UUID'
              requires :start_date, type: String, desc: 'The start time, default is one year ago'
              optional :end_date,   type: String, desc: 'The end time, default is now if end date is in the future'
            end
            get do
              current_time = Time.zone.now
              end_date = params[:end_date].present? ? Time.zone.parse(params[:end_date]) : current_time
              Xikolo.api(:learnanalytics).value!.rel(:metric).get(
                name: 'QuizPointsTimebased',
                user_id: current_user.id,
                course_id: params[:course_id],
                start_date: params[:start_date],
                end_date: [end_date, current_time].min
              ).value!
            end
          end

          namespace 'timebased_visits' do
            desc 'Returns all user items visits timebased as time series grouped by day'
            params do
              requires :course_id,  type: String, desc: 'The course UUID'
              requires :start_date, type: String, desc: 'The start time, default is one year ago'
              optional :end_date,   type: String, desc: 'The end time, default is now if end date is in the future'
            end
            get do
              current_time = Time.zone.now
              end_date = params[:end_date].present? ? Time.zone.parse(params[:end_date]) : current_time
              Xikolo.api(:learnanalytics).value!.rel(:metric).get(
                name: 'ItemVisitsTimebased',
                user_id: current_user.id,
                course_id: params[:course_id],
                start_date: params[:start_date],
                end_date: [end_date, current_time].min
              ).value!
            end
          end
        end

        namespace 'quizzes' do
          namespace 'submit_duration' do
            desc 'Returns the user\'s submit duration statistics'
            params do
              requires :course_id, type: String, desc: 'The course UUID'
            end
            get do
              Xikolo.api(:learnanalytics).value!.rel(:metric).get(
                name: 'QuizSubmitDuration',
                user_id: current_user.id,
                course_id: params[:course_id]
              ).value!
            end
          end

          namespace 'timeliness' do
            desc 'Returns the user\'s timeliness statistics'
            params do
              requires :course_id, type: String, desc: 'The course UUID'
            end
            get do
              Xikolo.api(:learnanalytics).value!.rel(:metric).get(
                name: 'QuizSubmissionTimeliness',
                user_id: current_user.id,
                course_id: params[:course_id]
              ).value!
            end
          end
        end

        namespace 'pinboard' do
          desc 'Returns the user\'s pinboard statistics'
          params do
            requires :course_id, type: String, desc: 'The course UUID'
          end
          get do
            stats = Xikolo.api(:learnanalytics).value!.rel(:metric).get(
              name: 'PinboardSummary',
              user_id: current_user.id,
              course_id: params[:course_id]
            ).value!

            {
              topicsViewed: stats.fetch('visited_question', 0),
              topicsCreated: stats.fetch('asked_question', 0),
              posts: stats.fetch('commented', 0) + stats.fetch('answered_question', 0),
            }
          end
        end

        namespace 'activity' do
          desc 'Returns all user activities timebased as time series grouped by hour and day of week'
          params do
            requires :course_id,  type: String, desc: 'The course UUID'
            requires :start_date, type: String, desc: 'The start time, default is one year ago'
            optional :end_date,   type: String, desc: 'The end time, default is now'
          end
          get do
            current_time = Time.zone.now
            end_date = params[:end_date].present? ? Time.zone.parse(params[:end_date]) : current_time
            Xikolo.api(:learnanalytics).value!.rel(:metric).get(
              name: 'CourseActivityTimebased',
              user_id: current_user.id,
              course_id: params[:course_id],
              start_date: params[:start_date],
              end_date: [end_date, current_time].min
            ).value!
          end
        end
      end
    end
  end
end
