# frozen_string_literal: true

require 'spec_helper'

describe 'Learning Evaluation: Update section progress', type: :feature do
  let!(:homework) { create(:item, :homework, max_dpoints: 20) }
  let(:user_id) { generate(:user_id) }

  before do
    Xikolo.config.persisted_learning_evaluation = true
  end

  describe 'Creating a result' do
    subject(:create_result) { Result.create! user_id:, item: homework, dpoints: 10 }

    it 'does not immediately create a new section progress' do
      expect { create_result }.not_to change(SectionProgress, :count)
    end

    it 'does not immediately update an existing section progress' do
      create(:section_progress, section: homework.section, user_id:)

      expect { create_result }.not_to change(SectionProgress, :count)
    end

    it '(asynchronously) creates a new section progress' do
      expect do
        Sidekiq::Testing.inline! { create_result }
      end.to change(SectionProgress, :count).by(1)

      expect(SectionProgress.last).to have_attributes(
        main_dpoints: 10,
        main_exercises: 1,
        bonus_dpoints: 0,
        bonus_exercises: 0,
        selftest_dpoints: 0,
        selftest_exercises: 0
      )
    end

    it '(asynchronously) updates an existing session progress' do
      create(:section_progress, section: homework.section, user_id:)

      expect do
        Sidekiq::Testing.inline! { create_result }
      end.not_to change(SectionProgress, :count)

      expect(SectionProgress.last).to have_attributes(
        main_dpoints: 10,
        main_exercises: 1,
        bonus_dpoints: 0,
        bonus_exercises: 0,
        selftest_dpoints: 0,
        selftest_exercises: 0
      )
    end
  end

  describe 'Updating a result' do
    subject(:update_result) { result.update!(dpoints: 20) }

    let(:result) { create(:result, user_id:, item: homework) }

    it 'does not immediately create a new section progress' do
      expect { update_result }.not_to change(SectionProgress, :count)
    end

    it 'does not immediately update an existing section progress' do
      create(:section_progress, section: homework.section, user_id:)

      expect { update_result }.not_to change(SectionProgress, :count)
    end

    it '(asynchronously) creates a new section progress' do
      expect do
        Sidekiq::Testing.inline! { update_result }
      end.to change(SectionProgress, :count).by(1)

      expect(SectionProgress.last).to have_attributes(
        main_dpoints: 20,
        main_exercises: 1,
        bonus_dpoints: 0,
        bonus_exercises: 0,
        selftest_dpoints: 0,
        selftest_exercises: 0
      )
    end

    it '(asynchronously) updates an existing session progress' do
      create(:section_progress, section: homework.section, user_id:)

      expect do
        Sidekiq::Testing.inline! { update_result }
      end.not_to change(SectionProgress, :count)

      expect(SectionProgress.last).to have_attributes(
        main_dpoints: 20,
        main_exercises: 1,
        bonus_dpoints: 0,
        bonus_exercises: 0,
        selftest_dpoints: 0,
        selftest_exercises: 0
      )
    end
  end

  describe 'Creating a visit' do
    subject(:create_visit) { Visit.create! user_id:, item: video }

    let!(:video) { create(:item) }

    it 'does not immediately create a new section progress' do
      expect { create_visit }.not_to change(SectionProgress, :count)
    end

    it 'does not immediately update an existing section progress' do
      create(:section_progress, section: video.section, user_id:)

      expect { create_visit }.not_to change(SectionProgress, :count)
    end

    it '(asynchronously) creates a new section progress' do
      expect do
        Sidekiq::Testing.inline! { create_visit }
      end.to change(SectionProgress, :count).by(1)

      expect(SectionProgress.last).to have_attributes(visits: 1)
    end

    it '(asynchronously) updates an existing session progress' do
      create(:section_progress, section: video.section, user_id:)

      expect do
        Sidekiq::Testing.inline! { create_visit }
      end.not_to change(SectionProgress, :count)

      expect(SectionProgress.last).to have_attributes(visits: 1)
    end
  end
end
