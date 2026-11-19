# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CourseService::LearningEvaluation::UpdateSectionProgressJob, type: :job do
  subject(:perform) do
    perform_enqueued_jobs do
      described_class.perform_later(section.id, user_id)
    end
  end

  let(:section) { create(:'course_service/section') }
  let(:user_id) { 'f03a00d1-bbad-40c9-972c-cb69e238af5c' }

  describe '#perform' do
    it 'generates a section progress' do
      expect { perform }.to change(CourseService::SectionProgress, :count).from(0).to(1)
    end
  end
end
