# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CourseService::EnrollmentCompletionWorker, type: :worker do
  let(:course) { create(:'course_service/course', records_released:) }
  let!(:enrollments) { create_list(:'course_service/enrollment', 3, course:) }

  context 'without records_released' do
    let(:records_released) { false }

    describe '#perform' do
      it 'generates enrollment completion for course' do
        expect(Msgr).to receive(:publish).with(kind_of(Hash), hash_including(to: 'xikolo.course.enrollment.completed')).exactly(0).times

        Sidekiq::Testing.inline! do
          described_class.perform_async(course.id)
        end
      end
    end
  end

  context 'with records_released' do
    let(:records_released) { true }

    describe '#perform' do
      it 'generates enrollment completion for course' do
        expect(Msgr).to receive(:publish).with(kind_of(Hash), hash_including(to: 'xikolo.course.enrollment.completed')).exactly(enrollments.length).times

        Sidekiq::Testing.inline! do
          described_class.perform_async(course.id)
        end
      end

      it 'generates enrollment completion for user' do
        expect(Msgr).to receive(:publish).with(kind_of(Hash), hash_including(to: 'xikolo.course.enrollment.completed')).once

        Sidekiq::Testing.inline! do
          described_class.perform_async(course.id, enrollments.first.user_id)
        end
      end
    end
  end
end
