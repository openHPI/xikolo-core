# frozen_string_literal: true

require 'spec_helper'

describe Section, type: :model do
  describe 'creation' do
    let(:default_attrs) { attributes_for(:section) }

    describe 'course content tree' do
      context 'for legacy courses' do
        let(:course) { create(:course) }

        it 'does not create a node' do
          expect do
            course.sections.create!(default_attrs)
          end.not_to change(Structure::Node, :count)
        end
      end

      context 'for courses with content tree' do
        let(:course) { create(:course, :with_content_tree) }

        it 'creates a node' do
          section = course.sections.create!(default_attrs)

          expect(section.node).to be_a Structure::Section
          expect(section.node.course).to eq course
          expect(section.node.parent).to eq course.node
        end
      end
    end
  end

  describe 'update' do
    describe 'learning evaluation' do
      subject(:update_section) { section.update!(update_params) }

      context 'for a legacy course' do
        let(:course) do
          create(:course, progress_calculated_at: 1.day.ago)
        end
        # NOTE: It is important to create the section (notice the bang) before
        # updating, otherwise we would test the result of both the item creation
        # and update here.
        let!(:section) do
          create(:section, course:, published: false, optional_section: false)
        end

        before do
          # Ensure having a clean state (no recalculation needed).
          section.update!(progress_stale_at: 2.days.ago)
          course.update!(progress_stale_at: 2.days.ago)
        end

        context 'publishing the section' do
          let(:update_params) { {published: true} }

          it 'marks the section and course for recalculation' do
            update_section

            expect(section.needs_recalculation?).to be true
            expect(section.course.needs_recalculation?).to be true
          end
        end

        context 'unpublishing the section' do
          let(:update_params) { {published: false} }
          let!(:section) do
            create(:section, course:, published: true)
          end

          it 'marks the section and course for recalculation' do
            update_section

            expect(section.needs_recalculation?).to be true
            expect(section.course.needs_recalculation?).to be true
          end
        end

        context 'setting the section to optional' do
          let(:update_params) { {optional_section: true} }

          it 'marks the section and course for recalculation' do
            update_section

            expect(section.needs_recalculation?).to be true
            expect(section.course.needs_recalculation?).to be true
          end
        end

        context 'setting the section to non-optional' do
          let(:update_params) { {optional_section: false} }
          let!(:section) do
            create(:section, course:, optional_section: true)
          end

          it 'marks the section and course for recalculation' do
            update_section

            expect(section.needs_recalculation?).to be true
            expect(section.course.needs_recalculation?).to be true
          end
        end

        context 'with the section and course already marked for recalculation' do
          let(:update_params) { {optional_section: true} }
          let(:course) do
            create(:course, progress_calculated_at: 1.week.ago)
          end
          let(:another_section) { create(:section, course:) }

          before do
            another_section.update!(progress_stale_at: 2.days.ago)
          end

          it 'keeps existing state' do
            update_section

            expect(another_section.needs_recalculation?).to be true
            expect(section.needs_recalculation?).to be true
            expect(course.needs_recalculation?).to be true
          end
        end

        context 'with a change irrelevant for the progress' do
          let(:update_params) { {title: 'Changed title'} }

          it 'does not mark the section nor the course for recalculation' do
            update_section

            expect(section.needs_recalculation?).to be false
            expect(section.course.needs_recalculation?).to be false
          end
        end
      end

      context 'for a course with content tree' do
        let(:course) do
          create(:course, :with_content_tree, progress_calculated_at: 1.day.ago)
        end
        # NOTE: It is important to create the section (notice the bang) before
        # updating, otherwise we would test the result of both the item creation
        # and update here.
        let!(:section) do
          create(:section, course:, published: false, optional_section: false)
        end

        before do
          # Ensure having a clean state (no recalculation needed).
          section.node.update!(progress_stale_at: 2.days.ago)
          course.node.update!(progress_stale_at: 2.days.ago)
        end

        context 'publishing the section' do
          let(:update_params) { {published: true} }

          it 'marks the section and course for recalculation' do
            update_section

            expect(section.node.needs_recalculation?).to be true
            expect(section.course.node.needs_recalculation?).to be true
          end
        end

        context 'unpublishing the section' do
          let(:update_params) { {published: false} }
          let!(:section) do
            create(:section, course:, published: true)
          end

          it 'marks the section and course for recalculation' do
            update_section

            expect(section.node.needs_recalculation?).to be true
            expect(section.course.node.needs_recalculation?).to be true
          end
        end

        context 'setting the section to optional' do
          let(:update_params) { {optional_section: true} }

          it 'marks the section and course for recalculation' do
            update_section

            expect(section.node.needs_recalculation?).to be true
            expect(section.course.node.needs_recalculation?).to be true
          end
        end

        context 'setting the section to non-optional' do
          let(:update_params) { {optional_section: false} }
          let!(:section) do
            create(:section, course:, optional_section: true)
          end

          it 'marks the section and course for recalculation' do
            update_section

            expect(section.node.needs_recalculation?).to be true
            expect(section.course.node.needs_recalculation?).to be true
          end
        end

        context 'with the section and course already marked for recalculation' do
          let(:update_params) { {optional_section: true} }
          let(:course) do
            create(:course, :with_content_tree, progress_calculated_at: 1.week.ago)
          end
          let(:another_section) { create(:section, course:) }

          before do
            another_section.node.update!(progress_stale_at: 2.days.ago)
          end

          it 'keeps existing state' do
            update_section

            expect(another_section.node.needs_recalculation?).to be true
            expect(section.node.needs_recalculation?).to be true
            expect(course.node.needs_recalculation?).to be true
          end
        end

        context 'with a change irrelevant for the progress' do
          let(:update_params) { {title: 'Changed title'} }

          it 'does not mark the section nor the course for recalculation' do
            update_section

            expect(section.node.needs_recalculation?).to be false
            expect(section.course.node.needs_recalculation?).to be false
          end
        end
      end
    end
  end

  describe 'deletion' do
    describe '#destroy' do
      subject(:destroy) { section.destroy; section.destroyed? }

      let(:section) { create(:section) }

      it { is_expected.to be true }

      context 'with items' do
        before do
          create(:item, section:)
        end

        it { is_expected.to be false }
        it { expect { destroy }.not_to change { section.items.count } }
      end

      context 'with forks' do
        let(:course) { create(:course, :with_content_tree) }
        let(:section) { create(:section, course:) }

        before do
          create(:fork, section:, course:)
        end

        it { is_expected.to be false }
        it { expect { destroy }.not_to change { section.forks.count } }
      end
    end

    describe '#destroyable?' do
      subject { section.destroyable? }

      let(:section) { create(:section) }

      it { is_expected.to be true }

      context 'with items' do
        before do
          create(:item, section:)
        end

        it { is_expected.to be false }
      end

      context 'with forks' do
        let(:course) { create(:course, :with_content_tree) }
        let(:section) { create(:section, course:) }

        before do
          create(:fork, section:, course:)
        end

        it { is_expected.to be false }
      end
    end

    describe 'learning evaluation' do
      context 'for a legacy course' do
        let(:course) do
          create(:course, progress_calculated_at: 1.day.ago)
        end
        # NOTE: It is important to create the section (notice the bang) before
        # destroying it, otherwise we would test the result of both the
        # section creation and destruction here.
        let!(:section) { create(:section, course:) }

        before do
          # Ensure having a clean state (no recalculation needed).
          section.update!(progress_stale_at: 2.days.ago)
          course.update!(progress_stale_at: 2.days.ago)
        end

        context 'when the section is published' do
          let!(:section) { create(:section, course:, published: true) }

          it 'marks the course for recalculation' do
            expect do
              section.destroy!
            end.to change { section.course.needs_recalculation? }.from(false).to(true)
          end
        end

        context 'when the section is not published' do
          let!(:section) { create(:section, course:, published: false) }

          it 'does not mark the course for recalculation' do
            expect do
              section.destroy!
            end.not_to change { section.course.needs_recalculation? }.from(false)
          end
        end

        context 'without any previous progress calculation' do
          let(:course) { create(:course) }

          it 'marks the course for recalculation' do
            section.destroy!

            expect(section.course.needs_recalculation?).to be true
          end
        end
      end

      context 'for a course with content tree' do
        let(:course) do
          create(:course, :with_content_tree, progress_calculated_at: 1.day.ago)
        end
        # NOTE: It is important to create the section (notice the bang) before
        # destroying it, otherwise we would test the result of both the
        # section creation and destruction here.
        let!(:section) { create(:section, course:) }

        before do
          # Ensure having a clean state (no recalculation needed).
          section.node.update!(progress_stale_at: 2.days.ago)
          course.node.update!(progress_stale_at: 2.days.ago)
        end

        context 'when the section is published' do
          let!(:section) { create(:section, course:, published: true) }

          it 'marks the course for recalculation' do
            expect do
              section.destroy!
            end.to change { section.course.node.needs_recalculation? }.from(false).to(true)
          end
        end

        context 'when the section is not published' do
          let!(:section) { create(:section, course:, published: false) }

          it 'does not mark the course for recalculation' do
            expect do
              section.destroy!
            end.not_to change { section.course.node.needs_recalculation? }.from(false)
          end
        end

        context 'without any previous progress calculation' do
          let(:course) { create(:course, :with_content_tree) }

          it 'marks the course for recalculation' do
            section.destroy!

            expect(section.course.node.needs_recalculation?).to be true
          end
        end
      end
    end
  end

  context 'in a course with start and end date' do
    let(:course) { create(:course) }

    context 'no start_date, no end date' do
      subject(:section) { create(:section, course:, start_date: nil, end_date: nil) }

      it 'has start date of course as effective start date' do
        expect(section.effective_start_date).to eq course.start_date
        expect(section.effective_start_date).not_to be_nil
        expect(section.effective_end_date).to be_nil
      end
    end

    context 'with start date before section start date' do
      subject(:section) { create(:section, course:, start_date: course.start_date - 1.day, end_date: nil) }

      it 'has start date of course as effective start date' do
        expect(section.effective_start_date).to eq course.start_date
        expect(section.effective_start_date).not_to eq section.start_date
        expect(section.effective_start_date).not_to be_nil
      end
    end

    context 'with start date after course start date' do
      subject(:section) { create(:section, course:, start_date: course.start_date + 1.day, end_date: nil) }

      it 'has start date of section as effective start date' do
        expect(section.effective_start_date).to eq section.start_date
        expect(section.effective_start_date).not_to eq course.start_date
        expect(section.effective_start_date).not_to be_nil
      end
    end

    context 'with end date before course end date' do
      subject(:section) { create(:section, course:, start_date: nil, end_date: course.end_date - 1.day) }

      it 'has end date of section as effective end date' do
        expect(section.effective_end_date).to eq section.end_date
        expect(section.effective_end_date).not_to eq course.end_date
      end
    end
  end

  context 'in course without start and end date' do
    let(:course) { create(:course, start_date: nil, end_date: nil) }

    context 'no start_date, no end date' do
      subject(:section) { create(:section, course:, start_date: nil, end_date: nil) }

      it 'has course dates as effective dates' do
        expect(section.effective_start_date).to be_nil
        expect(section.effective_end_date).to be_nil
      end
    end

    context 'with start date and end date' do
      subject(:section) { create(:section, course:) }

      it 'has start date of course as effective start date' do
        expect(section.effective_start_date).to eq section.start_date
        expect(section.effective_start_date).not_to be_nil
        expect(section.effective_end_date).to eq section.end_date
        expect(section.effective_end_date).not_to be_nil
      end
    end
  end

  context 'with alternative_state' do
    subject(:section) { create(:section) }

    it "has alternative_state set to 'none'" do
      expect(section.alternative_state).to eq 'none'
    end

    it 'does not act as a parent section' do
      expect(section).not_to be_parent
    end

    context 'as alternative parent section' do
      subject(:section) { create(:section, alternative_state: 'parent') }

      it 'acts as a parent section' do
        expect(section.alternative_state).to eq 'parent'
        expect(section).to be_parent
      end
    end

    context 'as child section' do
      subject(:section) { create(:section, alternative_state: 'child') }

      it 'does not act as a parent section' do
        expect(section.alternative_state).to eq 'child'
        expect(section).not_to be_parent
      end
    end
  end
end
