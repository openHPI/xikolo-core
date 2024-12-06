# frozen_string_literal: true

module Xikolo
  module V2
    class ProgressStats
      class << self
        def exercise_schema
          {
            exercises_available: :integer,
            exercises_taken: :integer,
            points_possible: :float,
            points_scored: :float,
          }
        end

        def visit_schema
          {
            items_available: :integer,
            items_visited: :integer,
            visits_percentage: :integer,
          }
        end

        def item_schema
          {
            id: :string,
            user_state: :string,
            max_points: :float,
            user_points: :float,
            time_effort: :integer,
            completed: :boolean,
          }
        end

        def exercise_data(exercises)
          if exercises
            {
              exercises_available: exercises['total_exercises'],
              exercises_taken: exercises['submitted_exercises'],
              points_possible: exercises['max_points'].round(2),
              points_scored: exercises['submitted_points'].round(2),
            }
          end
        end

        def visit_data(visits)
          if visits
            {
              items_available: visits['total'],
              items_visited: visits['user'],
              visits_percentage: visits['percentage'],
            }
          end
        end

        def item_data(item)
          if item
            {
              id: item['id'],
              user_state: item['user_state'],
              max_points: item['max_points'],
              user_points: item['user_points'],
              time_effort: item['time_effort'],
              completed: completed?(item),
            }
          end
        end

        def completed?(item)
          (%w[quiz peer_assessment lti_exercise].exclude?(item['content_type']) && item['user_state'] == 'visited') ||
            %w[submitted graded].include?(item['user_state'])
        end
      end
    end
  end
end
