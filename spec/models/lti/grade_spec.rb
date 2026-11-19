# frozen_string_literal: true

require 'spec_helper'

describe Lti::Grade, type: :model do
  subject(:grade) { build(:lti_grade) }

  describe '(validations)' do
    it { is_expected.to accept_values_for(:lti_gradebook_id, SecureRandom.uuid) }
    it { is_expected.to accept_values_for(:value, 0.5) }
    it { is_expected.not_to accept_values_for(:gradebook, nil) }
    it { is_expected.not_to accept_values_for(:value, nil) }
    it { is_expected.not_to accept_values_for(:value, '') }
  end

  # TODO: This should test model creation, not the method, once we auto-enable this feature.
  describe '#schedule_publication!' do
    subject(:schedule_publication) { grade.schedule_publication! }

    let(:grade) { create(:lti_grade, value: 0.5) }
    let!(:item) { create(:item, content_type: 'lti_exercise', content_id: grade.gradebook.lti_exercise_id, max_dpoints: 30) }

    it 'schedules a worker' do
      expect { schedule_publication }.to have_enqueued_job(Lti::PublishGradeJob)
        .with(grade.id)
        .on_queue('default')
    end

    it '(asynchronously) sends the correct result to xi-course' do
      request = Stub.request(
        :course, :put, "/results/#{grade.id}",
        body: {user_id: grade.gradebook.user_id, item_id: item.id, points: 1.5}
      ).to_return Stub.response(status: 201)

      perform_enqueued_jobs do
        schedule_publication
      end

      expect(request).to have_been_requested
    end

    context 'when the submission deadline has passed' do
      let!(:item) do
        create(
          :item,
          content_type: 'lti_exercise',
          content_id: grade.gradebook.lti_exercise_id,
          max_dpoints: 30,
          submission_deadline: 1.day.ago
        )
      end

      it 'marks the item completed without awarding points' do
        request = Stub.request(
          :course, :put, "/results/#{grade.id}",
          body: {user_id: grade.gradebook.user_id, item_id: item.id, points: 0}
        ).to_return Stub.response(status: 201)

        perform_enqueued_jobs do
          schedule_publication
        end

        expect(request).to have_been_requested
      end
    end

    context 'when the submission deadline is in the future' do
      let!(:item) do
        create(
          :item,
          content_type: 'lti_exercise',
          content_id: grade.gradebook.lti_exercise_id,
          max_dpoints: 30,
          submission_deadline: 1.day.from_now
        )
      end

      it 'awards points' do
        request = Stub.request(
          :course, :put, "/results/#{grade.id}",
          body: {user_id: grade.gradebook.user_id, item_id: item.id, points: 1.5}
        ).to_return Stub.response(status: 201)

        perform_enqueued_jobs do
          schedule_publication
        end

        expect(request).to have_been_requested
      end
    end
  end
end
