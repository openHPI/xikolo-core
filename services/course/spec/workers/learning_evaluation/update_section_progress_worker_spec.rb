# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LearningEvaluation::UpdateSectionProgressWorker, type: :worker do
  subject(:perform) do
    Sidekiq::Testing.inline! do
      described_class.perform_async(section.id, user_id)
    end
  end

  let(:section) { create(:'course_service/section') }
  let(:user_id) { 'f03a00d1-bbad-40c9-972c-cb69e238af5c' }

  context 'without persisted_learning_evaluation config' do
    before do
      xi_config <<~YML
        persisted_learning_evaluation: false
      YML
    end

    describe '#perform' do
      it 'generates no section progress' do
        expect { perform }.not_to change(SectionProgress, :count)
      end
    end
  end

  context 'with persisted_learning_evaluation config' do
    before do
      xi_config <<~YML
        persisted_learning_evaluation: true
      YML
    end

    describe '#perform' do
      it 'generates a section progress' do
        expect { perform }.to change(SectionProgress, :count).from(0).to(1)
      end
    end
  end
end
