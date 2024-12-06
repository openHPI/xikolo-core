# frozen_string_literal: true

require 'spec_helper'

describe SectionProgress::Calculate, type: :operation do
  subject(:calculate) { described_class.call(section.id, user_id, **params) }

  let(:params) { {} }
  let(:section) { create(:section) }
  let(:item) { create(:item, :homework, :with_max_points, section:) }
  let(:user_id) { generate(:user_id) }

  before do
    xi_config <<~YML
      persisted_learning_evaluation: true
    YML

    create(:visit, item:, user_id:)
    create(:result, item:, user_id:, dpoints: 10)
  end

  around {|example| Sidekiq::Testing.inline!(&example) }

  it 'creates / updates the section progress and triggers a recalculation' do
    # Creating a visit / result already creates a section progress, reset it.
    SectionProgress.first.update!(visits: 0, main_dpoints: 0, main_exercises: 0)

    expect { calculate }.not_to change(SectionProgress, :count).from(1)
    expect(SectionProgress.first).to have_attributes(
      section_id: section.id,
      user_id:,
      visits: 1,
      main_dpoints: 10,
      main_exercises: 1
    )
  end

  it 'creates / updates the corresponding course progress' do
    # Creating a visit / result already creates a course progress, reset it.
    CourseProgress.first.update!(visits: 0, main_dpoints: 0, main_exercises: 0, max_dpoints: 0, max_visits: 0)

    expect { calculate }.not_to change(CourseProgress, :count).from(1)
    expect(CourseProgress.first).to have_attributes(
      course_id: section.course_id,
      user_id:,
      visits: 1,
      main_dpoints: 10,
      main_exercises: 1,
      max_dpoints: 10,
      max_visits: 1
    )
  end

  context 'when explicitly skipping the course progress update' do
    let(:params) { {update_course_progress: false} }

    it 'does not create / update the corresponding course progress' do
      # Creating a visit / result already creates a course progress, reset it.
      CourseProgress.first.update!(visits: 0, main_dpoints: 0, main_exercises: 0, max_dpoints: 0, max_visits: 0)

      expect { calculate }.not_to change(CourseProgress, :count).from(1)
      expect(CourseProgress.first).to have_attributes(
        course_id: section.course_id,
        user_id:,
        visits: 0,
        main_dpoints: 0,
        main_exercises: 0,
        max_dpoints: 0,
        max_visits: 0
      )
    end
  end

  context 'with stale date' do
    let(:params) { {stale_at: 5.minutes.ago} }

    it 'creates *and calculates* the section progress if none exists' do
      # Creating a visit / result already creates a course progress, reset it.
      SectionProgress.first.destroy

      expect { calculate }.to change(SectionProgress, :count).from(0).to(1)
      expect(SectionProgress.first).to have_attributes(
        section_id: section.id,
        user_id:,
        visits: 1,
        main_dpoints: 10,
        main_exercises: 1
      )
    end

    context 'with outdated section progress' do
      let(:section_progress) { SectionProgress.first }

      it 'updates the existing section progress if it has not yet been updated' do
        section_progress.update!(updated_at: 10.minutes.ago, visits: 2, main_dpoints: 0, main_exercises: 0)

        expect(section_progress).to have_attributes(
          section_id: section.id,
          user_id:,
          visits: 2,
          main_dpoints: 0,
          main_exercises: 0
        )
        expect { calculate }.not_to change(SectionProgress, :count).from(1)
        expect(section_progress.reload).to have_attributes(
          section_id: section.id,
          user_id:,
          visits: 1,
          main_dpoints: 10,
          main_exercises: 1
        )
      end
    end

    context 'with already updated section progress' do
      let(:section_progress) { SectionProgress.first }

      it 'skips the additional update' do
        section_progress.update!(updated_at: 1.minute.ago, visits: 2, main_dpoints: 0, main_exercises: 0)

        expect(section_progress).to have_attributes(
          section_id: section.id,
          user_id:,
          visits: 2,
          main_dpoints: 0,
          main_exercises: 0
        )
        expect { calculate }.not_to change(SectionProgress, :count).from(1)
        expect(section_progress.reload).to have_attributes(
          section_id: section.id,
          user_id:,
          visits: 2,
          main_dpoints: 0,
          main_exercises: 0
        )
      end
    end
  end
end
