# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'LearningEvaluation: Recalculations: Create', type: :request do
  subject(:recalculate) do
    post "/courses/#{course.course_code}/recalculations",
      params: {course_id: course.course_code},
      headers: {'HTTP_AUTHORIZATION' => "Xikolo-Session session_id=#{stub_session_id}"}
  end

  let!(:course) { create(:course, progress_calculated_at: 70.minutes.ago, progress_stale_at: 20.minutes.ago) }
  let(:course_resource) { build(:'course:course', course_code: course.course_code) }
  let(:permissions) { %w[course.course.recalculate] }

  before do
    stub_user_request(permissions:)

    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .to_return Stub.json(course_resource)
  end

  context 'without persisted learning evaluation enabled' do
    before do
      xi_config <<~YML
        persisted_learning_evaluation: false
      YML
    end

    it 'responds with 404 Not Found, i.e. does not allow triggering recalculation' do
      expect { recalculate }.to raise_error AbstractController::ActionNotFound
    end
  end

  context 'with persisted learning evaluation enabled' do
    let(:recalculation_stub) do
      Stub.request(:course, :post, "/courses/#{course.course_code}/learning_evaluation")
        .to_return Stub.response(status: 200)
    end

    before do
      xi_config <<~YML
        persisted_learning_evaluation: true
      YML

      recalculation_stub
    end

    context 'with insufficient permissions for recalculation' do
      let(:permissions) { [] }

      it 'responds with 302 Found, i.e. redirects to root' do
        recalculate
        expect(response).to redirect_to :root
      end
    end

    context 'for a course with content tree' do
      before do
        course.node.update!(progress_stale_at: 20.minutes.ago)
      end

      it 'makes the corresponding request to xi-course to trigger the recalculation' do
        recalculate
        expect(recalculation_stub).to have_been_requested
        expect(response).to redirect_to "/courses/#{course.course_code}/sections"
        expect(flash[:success].first).to eq("The recalculation of learners' progresses for this course has been started.")
      end

      context 'with recalculation failing at the service' do
        let(:recalculation_stub) do
          Stub.request(:course, :post, "/courses/#{course.course_code}/learning_evaluation")
            .to_return Stub.response(status: 422)
        end

        it 'shows an error message in the flash block' do
          recalculate
          expect(response).to redirect_to "/courses/#{course.course_code}/sections"
          expect(flash[:error].first).to include("The recalculation of learners' progresses for this course could not be started.")
        end
      end

      context 'with recalculation triggered within one hour' do
        let(:course) { create(:course, progress_calculated_at: 50.minutes.ago) }

        it 'does not re-trigger the calculation' do
          recalculate
          expect(recalculation_stub).not_to have_been_requested
          expect(response).to redirect_to "/courses/#{course.course_code}/sections"
          expect(flash[:error].first).to include("The recalculation of learners' progresses for this course has been recently triggered. Please try again later.")
        end
      end
    end

    context 'for a legacy course' do
      let(:course) { create(:course_legacy, progress_stale_at: 20.minutes.ago) }

      it 'makes the corresponding request to xi-course to trigger the recalculation' do
        recalculate
        expect(recalculation_stub).to have_been_requested
        expect(response).to redirect_to "/courses/#{course.course_code}/sections"
        expect(flash[:success].first).to eq("The recalculation of learners' progresses for this course has been started.")
      end

      context 'with recalculation failing at the service' do
        let(:recalculation_stub) do
          Stub.request(:course, :post, "/courses/#{course.course_code}/learning_evaluation")
            .to_return Stub.response(status: 422)
        end

        it 'shows an error message in the flash block' do
          recalculate
          expect(response).to redirect_to "/courses/#{course.course_code}/sections"
          expect(flash[:error].first).to include("The recalculation of learners' progresses for this course could not be started.")
        end
      end

      context 'with recalculation triggered within one hour' do
        let(:course) { create(:course_legacy, progress_calculated_at: 50.minutes.ago, progress_stale_at: 20.minutes.ago) }

        it 'does not re-trigger the calculation' do
          recalculate
          expect(recalculation_stub).not_to have_been_requested
          expect(response).to redirect_to "/courses/#{course.course_code}/sections"
          expect(flash[:error].first).to include("The recalculation of learners' progresses for this course has been recently triggered. Please try again later.")
        end
      end
    end
  end
end
