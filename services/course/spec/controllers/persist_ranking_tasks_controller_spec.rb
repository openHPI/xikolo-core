# frozen_string_literal: true

require 'spec_helper'

describe PersistRankingTasksController, type: :controller do
  subject { action }

  let(:json) { JSON.parse response.body }
  let(:default_params) { {format: 'json'} }
  let(:course) { create(:course, end_date: 1.day.ago) }
  let(:section) { create(:section, course:) }
  let(:item) do
    create(:item, section:, content_type: :quiz,
      exercise_type: 'main', max_dpoints: 100)
  end
  let(:start_quantile) { nil }
  let(:start_quantiled_user_dpoints) { nil }

  describe "POST 'create'" do
    let(:action) { -> { post :create, params: {course_id: course.id} } }

    context 'response' do
      subject { action.call }

      its(:status) { is_expected.to eq 201 }
    end

    it 'creates a new persist ranking worker job' do
      expect { action.call }.to change(PersistRankingWorker.jobs, :size).from(0).to(1)
    end

    context 'with worker execution' do
      around do |example|
        Sidekiq::Testing.inline!(&example)
      end

      shared_examples 'generate correct rankings' do
        let(:results_and_quantils) do
          self.class.results_and_quantils
        end
        let!(:enrollments) do
          results_and_quantils.map.with_index do |(point, _), i|
            user_id = generate(:user_id)
            unless point.nil?
              create :result, dpoints: point,
                item:, user_id:
            end
            create(:enrollment, course:,
              user_id:,
              quantile: start_quantile,
              quantiled_user_dpoints: start_quantiled_user_dpoints,
              deleted: i % 2 ? true : false)
          end
        end

        def quantile_of(index)
          enrollments[index].reload.quantile
        end

        def quantiled_points_of(index)
          enrollments[index].reload.quantiled_user_dpoints
        end

        results_and_quantils.each_with_index do |(points, quantile), i|
          it do
            if quantile == start_quantile
              expect { subject.call }.not_to change { quantile_of i }
            else
              expect { subject.call }.to change { quantile_of i }.from(start_quantile).to(quantile)
            end
          end

          it do
            points = nil if points && (points < 50)
            if points == start_quantiled_user_dpoints
              expect { subject.call }.not_to change { quantiled_points_of i }
            else
              expect { subject.call }.to change { quantiled_points_of i }.from(start_quantiled_user_dpoints).to(points)
            end
          end
        end
      end

      context 'one course' do
        def self.results_and_quantils
          [
            [100, 1],
            [90, 0.6],
            [100, 1],
            [95, 0.8],
            [90, 0.6],
            [nil, nil],
            [49, nil],
            [50, 0.3],
            [0, nil],
            [81, 0.4],
            [94, 0.7],
            [50, 0.3],
            [50, 0.3],
          ]
        end
        it_behaves_like 'generate correct rankings'
      end

      context 'empty course' do
        def self.results_and_quantils
          []
        end
        it_behaves_like 'generate correct rankings'
      end

      context 'a course without any achieved point' do
        def self.results_and_quantils
          [
            [nil, nil],
            [nil, nil],
            [0, nil],
          ]
        end
        it_behaves_like 'generate correct rankings'
      end

      context 'a course without points' do
        let(:item) do
          create(:item, section:, content_type: :quiz,
            exercise_type: 'main', max_dpoints: 0)
        end

        def self.results_and_quantils
          [
            [nil, nil],
            [nil, nil],
            [0, nil],
          ]
        end
        it_behaves_like 'generate correct rankings'
      end

      context 'a course with only one user with certificate' do
        def self.results_and_quantils
          [
            [nil, nil],
            [50, 1],
            [0, nil],
          ]
        end
        it_behaves_like 'generate correct rankings'
      end

      context 'a course with previous rankings' do
        let(:start_quantile) { 0.5 }
        let(:start_quantiled_user_dpoints) { 25 }

        def self.results_and_quantils
          [
            [nil, nil],
            [50, 1],
            [25, nil],
            [49, nil],
            [0, nil],
          ]
        end
        it_behaves_like 'generate correct rankings'
      end
    end
  end
end
