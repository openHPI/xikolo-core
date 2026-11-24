# frozen_string_literal: true

require 'spec_helper'

describe 'Enrollment: Update', type: :request do
  let(:api) { restify_with_headers(course_service.root_url).get.value! }

  let(:user_id) { create(:'account_service/user').id }

  around do |example|
    perform_enqueued_jobs { example.run }
  end

  def patch(data)
    api.rel(:enrollment).patch(data, params: {id: enrollment.id}).value!
  end

  context 'updating completed' do
    let(:enrollment) do
      create(:'course_service/enrollment',
        user_id:,
        completed:,
        course:)
    end
    let(:completed) { nil }
    let(:course) { create(:'course_service/course') }
    let(:fetch_learning_evaluation) do
      CourseService::Enrollment.with_learning_evaluation(CourseService::Enrollment.all).find(enrollment.id)
    end

    context 'with auto-state true' do
      let(:course) { create(:'course_service/course', records_released: true) }
      let(:section) { create(:'course_service/section', course:) }
      let(:item) { create(:'course_service/item', section:, exercise_type: 'main', content_type: 'QuizService::Quiz', max_dpoints: 50) }

      before do
        create(:'course_service/result', item:, user_id:, dpoints: 49)

        CourseService::LearningEvaluation::UpdateCourseProgressJob
          .perform_now(course.id, user_id)
      end

      context 'with previously nil' do
        let(:completed) { nil }

        it 'assign nil should stay to auto-mode' do
          expect { patch completed: nil }.not_to \
            change { enrollment.reload.completed }.from(nil)
        end

        it 'assign true should stay to auto-mode' do
          expect { patch completed: true }.not_to \
            change { enrollment.reload.completed }.from(nil)
        end

        it 'assign false should change it to false' do
          expect { patch completed: false }.to \
            change { enrollment.reload.completed }.from(nil).to(false)
        end
      end

      context 'with previously true forced' do
        let(:completed) { true }

        it 'assign nil should switch to auto-mode' do
          expect { patch completed: nil }.to \
            change { enrollment.reload.completed }.from(true).to(nil)
        end

        it 'assign true should return to auto-mode' do
          expect { patch completed: true }.to \
            change { enrollment.reload.completed }.from(true).to(nil)
        end

        it 'assign false should change it to false' do
          expect { patch completed: false }.to \
            change { enrollment.reload.completed }.from(true).to(false)
        end
      end

      context 'with previously false forced' do
        let(:completed) { false }

        it 'assign nil should switch to auto-mode' do
          expect { patch completed: nil }.to \
            change { enrollment.reload.completed }.from(false).to(nil)
        end

        it 'assign true should return to auto-mode' do
          expect { patch completed: true }.to \
            change { enrollment.reload.completed }.from(false).to(nil)
        end

        it 'assign false should not change it' do
          expect { patch completed: false }.not_to \
            change { enrollment.reload.completed }.from(false)
        end
      end
    end

    context 'with auto-state false' do
      before do
        e = fetch_learning_evaluation
        e.completed = nil
        expect(e.completed?).to be false
      end

      context 'with previously nil' do
        let(:completed) { nil }

        it 'assign nil should stay to auto-mode' do
          expect { patch completed: nil }.not_to \
            change { enrollment.reload.completed }.from(nil)
        end

        it 'assign true should change it to true' do
          expect { patch completed: true }.to \
            change { enrollment.reload.completed }.from(nil).to(true)
        end

        it 'assign false should stay to auto-mode' do
          expect { patch completed: false }.not_to \
            change { enrollment.reload.completed }.from(nil)
        end
      end

      context 'with previously true forced' do
        let(:completed) { true }

        it 'assign nil should switch to auto-mode' do
          expect { patch completed: nil }.to \
            change { enrollment.reload.completed }.from(true).to(nil)
        end

        it 'assign true should not change it' do
          expect { patch completed: true }.not_to \
            change { enrollment.reload.completed }.from(true)
        end

        it 'assign false should return to auto-mode' do
          expect { patch completed: false }.to \
            change { enrollment.reload.completed }.from(true).to(nil)
        end
      end

      context 'with previously false forced' do
        let(:completed) { false }

        it 'assign nil should switch to auto-mode' do
          expect { patch completed: nil }.to \
            change { enrollment.reload.completed }.from(false).to(nil)
        end

        it 'assign true should change it to true' do
          expect { patch completed: true }.to \
            change { enrollment.reload.completed }.from(false).to(true)
        end

        it 'assign false should return to auto-mode' do
          expect { patch completed: false }.to \
            change { enrollment.reload.completed }.from(false).to(nil)
        end
      end
    end
  end

  context 'with forced_submission_date' do
    let!(:now) { DateTime.now.midnight }
    let(:enrollment) { create(:'course_service/enrollment', user_id:, forced_submission_date: nil) }

    it 'cannot be set by UPDATE' do
      expect do
        patch forced_submission_date: now
      end.not_to change {
        enrollment.reload.forced_submission_date
      }.from nil
    end
  end
end
