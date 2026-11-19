# frozen_string_literal: true

require 'spec_helper'

describe CourseService::Item, type: :model do
  subject(:item) { create(:'course_service/item', item_params) }

  let(:item_params) { {} }

  describe 'validation' do
    it { is_expected.to accept_values_for(:exercise_type, nil, 'video', 'richtext', 'quiz', 'lti_exercise') }
    it { is_expected.to accept_values_for(:submission_deadline, '', nil) }

    context 'for quizzes' do
      subject(:item) { create(:'course_service/item', :homework) }

      it { is_expected.not_to accept_values_for(:exercise_type, '', nil) }
    end

    context 'for scored cmi5 items' do
      subject(:item) do
        create(
          :'course_service/item',
          content_type: 'cmi5',
          exercise_type: 'selftest',
          max_dpoints: 100
        )
      end

      it { is_expected.to accept_values_for(:exercise_type, 'selftest') }
      it { is_expected.not_to accept_values_for(:exercise_type, '', nil, 'main', 'bonus', 'survey') }
    end

    context 'for ungraded cmi5 items' do
      subject(:item) do
        create(
          :'course_service/item',
          content_type: 'cmi5',
          exercise_type: nil,
          max_dpoints: nil
        )
      end

      it { is_expected.to accept_values_for(:exercise_type, '', nil) }
    end
  end

  describe 'creation' do
    let(:default_attrs) { attributes_for(:'course_service/item') }

    describe 'course content tree' do
      let(:section) { create(:'course_service/section', course:) }

      context 'for a legacy course' do
        let(:course) { create(:'course_service/course') }

        it 'does not create a node' do
          expect do
            section.items.create!(default_attrs)
          end.not_to change(CourseService::Structure::Node, :count)
        end
      end

      context 'for a course with content tree' do
        let(:course) { create(:'course_service/course', :with_content_tree) }

        it 'creates a node' do
          item = section.items.create!(default_attrs)

          expect(item.node).to be_a CourseService::Structure::Item
          expect(item.node.course).to eq course
          expect(item.node.parent).to eq section.node
        end
      end
    end

    describe 'learning evaluation' do
      subject(:create_item) { section.items.create!(default_attrs) }

      context 'for a legacy course' do
        let(:course) do
          create(:'course_service/course', progress_calculated_at: 1.day.ago)
        end
        let(:section) { create(:'course_service/section', course:) }

        before do
          # Ensure having a clean state (no recalculation needed).
          section.update!(progress_stale_at: 2.days.ago)
          course.update!(progress_stale_at: 2.days.ago)
        end

        context 'when the item is published' do
          let(:default_attrs) { super().merge(published: true) }

          it 'marks the section and course for recalculation' do
            create_item

            expect(section.needs_recalculation?).to be true
            expect(section.course.needs_recalculation?).to be true
          end
        end

        context 'when the item is not published' do
          let(:default_attrs) { super().merge(published: false) }

          it 'does not mark the section nor the course for recalculation' do
            create_item

            expect(section.needs_recalculation?).to be false
            expect(section.course.needs_recalculation?).to be false
          end
        end

        context 'without any previous progress calculation' do
          let(:course) { create(:'course_service/course') }

          it 'marks the section and course for recalculation' do
            create_item

            expect(section.needs_recalculation?).to be true
            expect(section.needs_recalculation?).to be true
          end
        end

        context 'in a non-published section' do
          let(:section) { create(:'course_service/section', course:, published: false) }

          it 'does not mark the section nor the course for recalculation' do
            create_item

            expect(section.needs_recalculation?).to be false
            expect(section.course.needs_recalculation?).to be false
          end
        end
      end

      context 'for a course with content tree' do
        let(:course) do
          create(:'course_service/course', :with_content_tree, progress_calculated_at: 1.day.ago)
        end
        let(:section) { create(:'course_service/section', course:) }

        before do
          # Ensure having a clean state (no recalculation needed).
          section.node.update!(progress_stale_at: 2.days.ago)
          course.node.update!(progress_stale_at: 2.days.ago)
        end

        context 'when the item is published' do
          let(:default_attrs) { super().merge(published: true) }

          it 'marks the section and course for recalculation' do
            create_item

            expect(section.node.needs_recalculation?).to be true
            expect(section.course.node.needs_recalculation?).to be true
          end
        end

        context 'when the item is not published' do
          let(:default_attrs) { super().merge(published: false) }

          it 'does not mark the section nor the course for recalculation' do
            create_item

            expect(section.node.needs_recalculation?).to be false
            expect(section.course.node.needs_recalculation?).to be false
          end
        end

        context 'without any previous progress calculation' do
          let(:course) { create(:'course_service/course', :with_content_tree) }

          it 'marks the section and course for recalculation' do
            create_item

            expect(section.node.needs_recalculation?).to be true
            expect(section.course.node.needs_recalculation?).to be true
          end
        end

        context 'in a non-published section' do
          let(:section) { create(:'course_service/section', course:, published: false) }

          it 'does not mark the section nor the course for recalculation' do
            create_item

            expect(section.node.needs_recalculation?).to be false
            expect(section.course.node.needs_recalculation?).to be false
          end
        end
      end
    end

    describe '[open_mode]' do
      context 'with a default of true' do
        before { Xikolo.config.open_mode['default_value'] = true }

        let(:default_attrs) { super().merge(section: create(:'course_service/section')) }

        it 'respects the default' do
          item = CourseService::Item.create! default_attrs
          expect(item.open_mode).to be true
        end

        it 'allows overwriting the default' do
          item = CourseService::Item.create! default_attrs.merge(open_mode: false)
          expect(item.open_mode).to be false
        end
      end

      context 'with a default of false' do
        before { Xikolo.config.open_mode['default_value'] = false }

        let(:default_attrs) { super().merge(section: create(:'course_service/section')) }

        it 'respects the default' do
          item = CourseService::Item.create! default_attrs
          expect(item.open_mode).to be false
        end

        it 'allows overwriting the default' do
          item = CourseService::Item.create! default_attrs.merge(open_mode: true)
          expect(item.open_mode).to be true
        end
      end
    end
  end

  describe 'update' do
    describe 'learning evaluation' do
      subject(:update_item) { item.update!(update_params) }

      context 'for a legacy course' do
        let(:course) do
          create(:'course_service/course', progress_calculated_at: 1.day.ago)
        end
        let(:section) { create(:'course_service/section', course:, published: true) }
        # NOTE: It is important to create the item (notice the bang) before
        # updating it, otherwise we would test the result of both the
        # item creation and update here.
        let!(:item) do # rubocop:disable RSpec/LetSetup
          create(:'course_service/item', :quiz, section:,
            published: false,
            optional: false,
            max_dpoints: 44)
        end

        before do
          # Ensure having a clean state (no recalculation needed).
          section.update!(progress_stale_at: 2.days.ago)
          course.update!(progress_stale_at: 2.days.ago)
        end

        context 'publishing the item' do
          let(:update_params) { {published: true} }

          it 'marks the section and course for recalculation' do
            update_item

            expect(section.needs_recalculation?).to be true
            expect(section.course.needs_recalculation?).to be true
          end
        end

        context 'unpublishing the item' do
          let(:update_params) { {published: false} }
          let!(:item) do
            create(:'course_service/item', :quiz, section:, published: true)
          end

          it 'marks the section and course for recalculation' do
            update_item

            expect(section.needs_recalculation?).to be true
            expect(section.course.needs_recalculation?).to be true
          end
        end

        context 'setting the item to optional' do
          let(:update_params) { {optional: true} }

          it 'marks the section and course for recalculation' do
            update_item

            expect(section.needs_recalculation?).to be true
            expect(section.course.needs_recalculation?).to be true
          end
        end

        context 'setting the item to non-optional' do
          let(:update_params) { {optional: false} }
          let!(:item) do
            create(:'course_service/item', :quiz, section:, optional: true)
          end

          it 'marks the section and course for recalculation' do
            update_item

            expect(section.needs_recalculation?).to be true
            expect(section.course.needs_recalculation?).to be true
          end
        end

        context "changing the item's points" do
          let(:update_params) { {max_dpoints: 50} }

          it 'marks the section and course for recalculation' do
            update_item

            expect(section.needs_recalculation?).to be true
            expect(section.course.needs_recalculation?).to be true
          end
        end

        context 'moving the item to another section' do
          let(:update_params) { {section_id: another_section.id} }
          let(:another_section) { create(:'course_service/section', course:, published: true) }

          before do
            another_section.update!(progress_stale_at: 2.days.ago)
          end

          context 'when the item is not published' do
            it 'does not mark any section nor the course for recalculation' do
              update_item

              expect(another_section.reload.needs_recalculation?).to be false
              expect(section.reload.needs_recalculation?).to be false
              expect(section.course.needs_recalculation?).to be false
            end
          end

          context 'when the item and both sections are published' do
            let!(:item) do
              create(:'course_service/item', :quiz, section:, published: true)
            end

            it 'marks all affected sections and the course for recalculation' do
              update_item

              expect(another_section.reload.needs_recalculation?).to be true
              expect(section.reload.needs_recalculation?).to be true
              expect(section.course.needs_recalculation?).to be true
            end

            # NOTE: This is regression test to ensure this case is not missed
            # when refactoring `Item#progress_relevant_change?`.
            context 'and updating the published state at the same time' do
              let(:update_params) { {section_id: another_section.id, published: false} }

              it 'marks all affected sections and the course for recalculation' do
                update_item

                expect(another_section.reload.needs_recalculation?).to be true
                expect(section.reload.needs_recalculation?).to be true
                expect(section.course.needs_recalculation?).to be true
              end
            end
          end

          context 'from a published to a non-published section' do
            let(:another_section) { create(:'course_service/section', course:, published: false) }
            let!(:item) do
              create(:'course_service/item', :quiz, section:, published: true)
            end

            it 'marks all affected sections and the course for recalculation' do
              update_item

              expect(another_section.reload.needs_recalculation?).to be false
              expect(section.reload.needs_recalculation?).to be true
              expect(section.course.needs_recalculation?).to be true
            end
          end

          context 'from a non-published to a published section' do
            let(:section) { create(:'course_service/section', course:, published: false) }
            let!(:item) do
              create(:'course_service/item', :quiz, section:, published: true)
            end

            it 'marks all affected sections and the course for recalculation' do
              update_item

              expect(another_section.reload.needs_recalculation?).to be true
              expect(section.reload.needs_recalculation?).to be false
              expect(section.course.needs_recalculation?).to be true
            end
          end

          context 'from a non-published to another non-published section' do
            let(:section) { create(:'course_service/section', course:, published: false) }
            let(:another_section) { create(:'course_service/section', course:, published: false) }
            let!(:item) do
              create(:'course_service/item', :quiz, section:, published: true)
            end

            it 'does not mark any section nor the course for recalculation' do
              update_item

              expect(another_section.reload.needs_recalculation?).to be false
              expect(section.reload.needs_recalculation?).to be false
              expect(section.course.needs_recalculation?).to be false
            end
          end
        end

        context 'with the section and course already marked for recalculation' do
          let(:update_params) { {max_dpoints: 50} }
          let(:course) do
            create(:'course_service/course', progress_calculated_at: 1.week.ago)
          end
          let(:another_section) { create(:'course_service/section', course:) }

          before do
            another_section.update!(progress_stale_at: 2.days.ago)
          end

          it 'keeps existing state' do
            update_item

            expect(another_section.needs_recalculation?).to be true
            expect(section.needs_recalculation?).to be true
            expect(section.course.needs_recalculation?).to be true
          end
        end

        context 'with a change irrelevant for the progress' do
          let(:update_params) { {title: 'Changed title'} }

          it 'does not mark the section nor the course for recalculation' do
            update_item

            expect(section.needs_recalculation?).to be false
            expect(section.course.needs_recalculation?).to be false
          end
        end

        context 'without any previous progress calculation' do
          let(:update_params) { {max_dpoints: 50} }
          let(:course) { create(:'course_service/course') }

          it 'marks the section and course for recalculation' do
            update_item

            expect(section.needs_recalculation?).to be true
            expect(section.course.needs_recalculation?).to be true
          end
        end

        context 'in a non-published section' do
          let(:update_params) { {max_dpoints: 50} }
          let(:section) { create(:'course_service/section', course:, published: false) }

          it 'does not mark the section nor the course for recalculation' do
            update_item

            expect(section.needs_recalculation?).to be false
            expect(section.course.needs_recalculation?).to be false
          end
        end
      end

      context 'for a course with content tree' do
        let(:course) do
          create(:'course_service/course', :with_content_tree, progress_calculated_at: 1.day.ago)
        end
        let(:section) { create(:'course_service/section', course:, published: true) }
        # NOTE: It is important to create the item (notice the bang) before
        # updating it, otherwise we would test the result of both the
        # item creation and update here.
        let!(:item) do # rubocop:disable RSpec/LetSetup
          create(:'course_service/item', :quiz, section:,
            published: false,
            optional: false,
            max_dpoints: 44)
        end

        before do
          # Ensure having a clean state (no recalculation needed).
          section.node.update!(progress_stale_at: 2.days.ago)
          course.node.update!(progress_stale_at: 2.days.ago)
        end

        context 'publishing the item' do
          let(:update_params) { {published: true} }

          it 'marks the section and course for recalculation' do
            update_item

            expect(section.node.needs_recalculation?).to be true
            expect(section.course.node.needs_recalculation?).to be true
          end
        end

        context 'unpublishing the item' do
          let(:update_params) { {published: false} }
          let!(:item) do
            create(:'course_service/item', :quiz, section:, published: true)
          end

          it 'marks the section and course for recalculation' do
            update_item

            expect(section.node.needs_recalculation?).to be true
            expect(section.course.node.needs_recalculation?).to be true
          end
        end

        context 'setting the item to optional' do
          let(:update_params) { {optional: true} }

          it 'marks the section and course for recalculation' do
            update_item

            expect(section.node.needs_recalculation?).to be true
            expect(section.course.node.needs_recalculation?).to be true
          end
        end

        context 'setting the item to non-optional' do
          let(:update_params) { {optional: false} }
          let!(:item) do
            create(:'course_service/item', :quiz, section:, optional: true)
          end

          it 'marks the section and course for recalculation' do
            update_item

            expect(section.node.needs_recalculation?).to be true
            expect(section.course.node.needs_recalculation?).to be true
          end
        end

        context "changing the item's points" do
          let(:update_params) { {max_dpoints: 50} }

          it 'marks the section and course for recalculation' do
            update_item

            expect(section.node.needs_recalculation?).to be true
            expect(section.course.node.needs_recalculation?).to be true
          end
        end

        context 'moving the item to another section' do
          let(:update_params) { {section_id: another_section.id} }
          let(:another_section) { create(:'course_service/section', course:, published: true) }

          before do
            another_section.node.update!(progress_stale_at: 2.days.ago)
          end

          context 'when the item is not published' do
            it 'does not mark any section nor the course for recalculation' do
              update_item

              expect(another_section.reload.node.needs_recalculation?).to be false
              expect(section.reload.node.needs_recalculation?).to be false
              expect(section.course.node.needs_recalculation?).to be false
            end
          end

          context 'when the item and both sections are published' do
            let!(:item) do
              create(:'course_service/item', :quiz, section:, published: true)
            end

            it 'marks all affected sections and the course for recalculation' do
              update_item

              expect(another_section.reload.node.needs_recalculation?).to be true
              expect(section.reload.node.needs_recalculation?).to be true
              expect(section.course.node.needs_recalculation?).to be true
            end

            # NOTE: This is regression test to ensure this case is not missed
            # when refactoring `Item#progress_relevant_change?`.
            context 'and updating the published state at the same time' do
              let(:update_params) { {section_id: another_section.id, published: false} }

              it 'marks all affected sections and the course for recalculation' do
                update_item

                expect(another_section.reload.node.needs_recalculation?).to be true
                expect(section.reload.node.needs_recalculation?).to be true
                expect(section.course.node.needs_recalculation?).to be true
              end
            end
          end

          context 'from a published to a non-published section' do
            let(:another_section) { create(:'course_service/section', course:, published: false) }
            let!(:item) do
              create(:'course_service/item', :quiz, section:, published: true)
            end

            it 'marks all affected sections and the course for recalculation' do
              update_item

              expect(another_section.reload.node.needs_recalculation?).to be false
              expect(section.reload.node.needs_recalculation?).to be true
              expect(section.course.node.needs_recalculation?).to be true
            end
          end

          context 'from a non-published to a published section' do
            let(:section) { create(:'course_service/section', course:, published: false) }
            let!(:item) do
              create(:'course_service/item', :quiz, section:, published: true)
            end

            it 'marks all affected sections and the course for recalculation' do
              update_item

              expect(another_section.reload.node.needs_recalculation?).to be true
              expect(section.reload.node.needs_recalculation?).to be false
              expect(section.course.node.needs_recalculation?).to be true
            end
          end

          context 'from a non-published to another non-published section' do
            let(:section) { create(:'course_service/section', course:, published: false) }
            let(:another_section) { create(:'course_service/section', course:, published: false) }
            let!(:item) do
              create(:'course_service/item', :quiz, section:, published: true)
            end

            it 'does not mark any section nor the course for recalculation' do
              update_item

              expect(another_section.reload.node.needs_recalculation?).to be false
              expect(section.reload.node.needs_recalculation?).to be false
              expect(section.course.node.needs_recalculation?).to be false
            end
          end
        end

        context 'with the section and course already marked for recalculation' do
          let(:update_params) { {max_dpoints: 50} }
          let(:course) do
            create(:'course_service/course', :with_content_tree, progress_calculated_at: 1.week.ago)
          end
          let(:another_section) { create(:'course_service/section', course:) }

          before do
            another_section.node.update!(progress_stale_at: 2.days.ago)
          end

          it 'keeps existing state' do
            update_item

            expect(another_section.node.needs_recalculation?).to be true
            expect(section.node.needs_recalculation?).to be true
            expect(section.course.node.needs_recalculation?).to be true
          end
        end

        context 'with a change irrelevant for the progress' do
          let(:update_params) { {title: 'Changed title'} }

          it 'does not mark the section nor the course for recalculation' do
            update_item

            expect(section.node.needs_recalculation?).to be false
            expect(section.course.node.needs_recalculation?).to be false
          end
        end

        context 'without any previous progress calculation' do
          let(:update_params) { {max_dpoints: 50} }
          let(:course) { create(:'course_service/course', :with_content_tree) }

          it 'marks the section and course for recalculation' do
            update_item

            expect(section.node.needs_recalculation?).to be true
            expect(section.course.node.needs_recalculation?).to be true
          end
        end

        context 'in a non-published section' do
          let(:update_params) { {max_dpoints: 50} }
          let(:section) { create(:'course_service/section', course:, published: false) }

          it 'does not mark the section nor the course for recalculation' do
            update_item

            expect(section.node.needs_recalculation?).to be false
            expect(section.course.node.needs_recalculation?).to be false
          end
        end
      end
    end
  end

  describe 'deletion' do
    describe 'learning evaluation' do
      context 'for a legacy course' do
        let(:course) do
          create(:'course_service/course', progress_calculated_at: 1.day.ago)
        end
        let(:section) { create(:'course_service/section', course:) }
        # NOTE: It is important to create the item (notice the bang) before
        # destroying it, otherwise we would test the result of both the
        # item creation and destruction here.
        let!(:item) { create(:'course_service/item', section:) }

        before do
          # Ensure having a clean state (no recalculation needed).
          section.update!(progress_stale_at: 2.days.ago)
          course.update!(progress_stale_at: 2.days.ago)
        end

        context 'when the item is published' do
          let!(:item) do
            create(:'course_service/item', :quiz, section:, published: true)
          end

          it 'marks the section and course for recalculation' do
            item.destroy!

            expect(section.reload.needs_recalculation?).to be true
            expect(section.course.needs_recalculation?).to be true
          end
        end

        context 'when the item is not published' do
          let!(:item) do
            create(:'course_service/item', :quiz, section:, published: false)
          end

          it 'does not mark the section nor the course for recalculation' do
            item.destroy!

            expect(section.reload.needs_recalculation?).to be false
            expect(section.course.needs_recalculation?).to be false
          end
        end

        context 'without any previous progress calculation' do
          let(:course) { create(:'course_service/course') }

          it 'marks the section and course for recalculation' do
            item.destroy!

            expect(section.needs_recalculation?).to be true
            expect(section.course.needs_recalculation?).to be true
          end
        end

        context 'in a non-published section' do
          let(:section) { create(:'course_service/section', course:, published: false) }

          it 'does not mark the section nor the course for recalculation' do
            item.destroy!

            expect(section.needs_recalculation?).to be false
            expect(section.course.needs_recalculation?).to be false
          end
        end
      end

      context 'for a course with content tree' do
        let(:course) do
          create(:'course_service/course', :with_content_tree, progress_calculated_at: 1.day.ago)
        end
        let(:section) { create(:'course_service/section', course:) }
        # NOTE: It is important to create the item (notice the bang) before
        # destroying it, otherwise we would test the result of both the
        # item creation and destruction here.
        let!(:item) { create(:'course_service/item', section:) }

        before do
          # Ensure having a clean state (no recalculation needed).
          section.node.update!(progress_stale_at: 2.days.ago)
          course.node.update!(progress_stale_at: 2.days.ago)
        end

        context 'when the item is published' do
          let!(:item) do
            create(:'course_service/item', :quiz, section:, published: true)
          end

          it 'marks the section and course for recalculation' do
            item.destroy!

            expect(section.reload.node.needs_recalculation?).to be true
            expect(section.course.node.needs_recalculation?).to be true
          end
        end

        context 'when the item is not published' do
          let!(:item) do
            create(:'course_service/item', :quiz, section:, published: false)
          end

          it 'does not mark the section nor the course for recalculation' do
            item.destroy!

            expect(section.reload.node.needs_recalculation?).to be false
            expect(section.course.node.needs_recalculation?).to be false
          end
        end

        context 'without any previous progress calculation' do
          let(:course) { create(:'course_service/course', :with_content_tree) }

          it 'marks the section and course for recalculation' do
            item.destroy!

            expect(section.node.needs_recalculation?).to be true
            expect(section.course.node.needs_recalculation?).to be true
          end
        end

        context 'in a non-published section' do
          let(:section) { create(:'course_service/section', course:, published: false) }

          it 'does not mark the section nor the course for recalculation' do
            item.destroy!

            expect(section.node.needs_recalculation?).to be false
            expect(section.course.node.needs_recalculation?).to be false
          end
        end
      end
    end
  end

  describe '.completed?' do
    %w[lti_exercise peer_assessment quiz].each do |content_type|
      it "counts #{content_type} items once graded or submitted" do
        expect(described_class.completed?(content_type:, user_state: 'graded')).to be true
        expect(described_class.completed?(content_type:, user_state: 'submitted')).to be true
        expect(described_class.completed?(content_type:, user_state: 'visited')).to be false
        expect(described_class.completed?(content_type:, user_state: 'new')).to be false
      end
    end

    it 'counts scored CMI5 items once graded or submitted' do
      expect(described_class.completed?(content_type: 'cmi5', user_state: 'graded', max_points: 100)).to be true
      expect(described_class.completed?(content_type: 'cmi5', user_state: 'submitted', max_points: 100)).to be true
      expect(described_class.completed?(content_type: 'cmi5', user_state: 'visited', max_points: 100)).to be false
      expect(described_class.completed?(content_type: 'cmi5', user_state: 'new', max_points: 100)).to be false
    end

    it 'counts non-scored CMI5 items once visited' do
      expect(described_class.completed?(content_type: 'cmi5', user_state: 'visited', max_points: 0)).to be true
      expect(described_class.completed?(content_type: 'cmi5', user_state: 'visited')).to be true
      expect(described_class.completed?(content_type: 'cmi5', user_state: 'graded', max_points: 0)).to be false
      expect(described_class.completed?(content_type: 'cmi5', user_state: 'new', max_points: 0)).to be false
    end

    it 'counts other items once visited' do
      expect(described_class.completed?(content_type: 'video', user_state: 'visited')).to be true
      expect(described_class.completed?(content_type: 'video', user_state: 'graded')).to be false
      expect(described_class.completed?(content_type: 'video', user_state: 'new')).to be false
    end
  end

  describe '#exam_locked_for?' do
    subject(:locked) { item.exam_locked_for?(user_id) }

    let(:item) do
      create(:'course_service/item', :quiz, exercise_type: 'exam', minimum_progress_percentage:,
        content_id: create(:'quiz_service/quiz', :with_valid_question_pool).id)
    end
    let(:minimum_progress_percentage) { 50 }
    let(:user_id) { generate(:user_id) }

    def create_progress(visits_percentage_fpoints)
      create(:'course_service/course_progress', course: item.section.course, user_id:, visits_percentage_fpoints:)
    end

    it 'is locked without a course progress' do
      expect(locked).to be true
    end

    it 'is locked below the required progress' do
      create_progress(49_99)
      expect(locked).to be true
    end

    it 'is unlocked once the required progress is reached' do
      create_progress(50_00)
      expect(locked).to be false
    end

    context 'without a user' do
      let(:user_id) { nil }

      it { is_expected.to be false }
    end

    context 'for items other than exams' do
      let(:item) { create(:'course_service/item', :homework) }

      it { is_expected.to be false }
    end

    context 'without a required progress' do
      let(:minimum_progress_percentage) { nil }

      it 'is locked below 75%' do
        create_progress(74_99)
        expect(locked).to be true
      end

      it 'is unlocked from 75%' do
        create_progress(75_00)
        expect(locked).to be false
      end
    end
  end

  describe '#effective_published' do
    # we don't consider course start / end dates here
    let!(:course) { create(:'course_service/course', start_date: nil, end_date: nil) }

    context 'published item in published section' do
      subject(:item) { create(:'course_service/item', section:, published: true) }

      let!(:section) { create(:'course_service/section', course:, published: true) }

      it 'is unpublished' do
        expect(item.effective_published).to be true
      end
    end

    context 'published item in unpublished section' do
      subject(:item) { create(:'course_service/item', section:, published: true) }

      let!(:section) { create(:'course_service/section', course:, published: false) }

      it 'is unpublished' do
        expect(item.effective_published).to be false
      end
    end

    context 'unpublished item in published section' do
      subject(:item) { create(:'course_service/item', section:, published: false) }

      let!(:section) { create(:'course_service/section', course:, published: true) }

      it 'is unpublished' do
        expect(item.effective_published).to be false
      end
    end

    context 'unpublished item in unpublished section' do
      subject(:item) { create(:'course_service/item', section:, published: false) }

      let!(:section) { create(:'course_service/section', course:, published: false) }

      it 'is unpublished' do
        expect(item.effective_published).to be false
      end
    end
  end

  describe '#effective_submission_deadline' do
    subject(:deadline) { item.effective_submission_deadline }

    let(:item_params) { {submission_deadline: DateTime.new(2000, 1, 1, 0, 0, 1)} }

    it 'is the submission_deadline' do
      expect(deadline.iso8601).to eq('2000-01-01T00:00:01Z')
    end

    context 'with item for user' do
      subject(:deadline) do
        item.for_user!(user_id)
        item.effective_submission_deadline
      end

      let(:user_id) { create(:'account_service/user').id }
      let(:enrollment_params) { {user_id:, course_id: item.section.course.id} }

      before { create(:'course_service/enrollment', enrollment_params) }

      it 'is the submission_deadline' do
        expect(deadline.iso8601).to eq('2000-01-01T00:00:01Z')
      end

      context 'with course reactivation' do
        let(:enrollment_params) { super().merge(forced_submission_date: DateTime.new(2000, 2, 2, 0, 0, 2)) }

        it 'is the forced submission date' do
          expect(deadline.iso8601).to eq('2000-02-02T00:00:02Z')
        end

        context 'with forced submission date not being more recent' do
          let(:item_params) { {submission_deadline: DateTime.new(2000, 3, 3, 0, 0, 3)} }

          it 'is the quiz submission date' do
            expect(deadline.iso8601).to eq('2000-03-03T00:00:03Z')
          end
        end
      end
    end
  end

  context 'in a section with start and end date' do
    # NOTE: We don't consider course start / end dates here.
    let!(:course) { create(:'course_service/course', start_date: nil, end_date: nil) }
    let!(:section) { create(:'course_service/section', course:) }

    context 'no start_date, no end date' do
      subject(:item) { create(:'course_service/item', section:, start_date: nil, end_date: nil) }

      it 'has dates of section as effective dates' do
        expect(item.effective_start_date).to eq section.start_date
        expect(item.effective_start_date).not_to be_nil
        expect(item.effective_end_date).to eq section.end_date
        expect(item.effective_end_date).not_to be_nil
      end
    end

    context 'with start date before section start date' do
      subject(:item) { create(:'course_service/item', section:, start_date: section.start_date - 1.day, end_date: nil) }

      it 'has start date of section as effective start date' do
        expect(item.effective_start_date).to eq section.start_date
        expect(item.effective_start_date).not_to eq item.start_date
        expect(item.effective_start_date).not_to be_nil
      end
    end

    context 'with start date after section start date' do
      subject(:item) { create(:'course_service/item', section:, start_date: section.start_date + 1.day, end_date: nil) }

      it 'has start date of item as effective start date' do
        expect(item.effective_start_date).to eq item.start_date
        expect(item.effective_start_date).not_to eq section.start_date
        expect(item.effective_start_date).not_to be_nil
      end
    end

    context 'with end date before section end date' do
      subject(:item) { create(:'course_service/item', section:, start_date: nil, end_date: section.end_date - 1.day) }

      it 'has end date of item as effective end date' do
        expect(item.effective_end_date).to eq item.end_date
        expect(item.effective_end_date).not_to eq section.end_date
        expect(item.effective_end_date).not_to be_nil
      end
    end

    context 'with end date after section end date' do
      subject(:item) { create(:'course_service/item', section:, start_date: nil, end_date: section.end_date + 1.day) }

      it 'has end date of section as effective end date' do
        expect(item.effective_end_date).to eq section.end_date
        expect(item.effective_end_date).not_to eq item.end_date
        expect(item.effective_end_date).not_to be_nil
      end
    end
  end

  context 'in a section without start and end date' do
    let!(:course) { create(:'course_service/course') }
    let!(:section) { create(:'course_service/section', course:, start_date: nil, end_date: nil) }

    context 'no start date, no end date' do
      subject(:item) { create(:'course_service/item', section:, start_date: nil, end_date: nil) }

      it 'has course start date as effective start date' do
        expect(item.effective_start_date).to eq course.start_date
        expect(item.effective_start_date).not_to be_nil
        expect(item.effective_end_date).to be_nil
      end
    end

    context 'with start date before course start date' do
      subject(:item) { create(:'course_service/item', section:, start_date: course.start_date - 1.day, end_date: nil) }

      it 'has start date of course as effective start date' do
        expect(item.effective_start_date).to eq course.start_date
        expect(item.effective_start_date).not_to eq item.start_date
        expect(item.effective_start_date).not_to be_nil
      end
    end

    context 'with start date after course start date' do
      subject(:item) { create(:'course_service/item', section:, start_date: course.start_date + 1.day, end_date: nil) }

      it 'has start date of item as effective start date' do
        expect(item.effective_start_date).to eq item.start_date
        expect(item.effective_start_date).not_to eq course.start_date
        expect(item.effective_start_date).not_to be_nil
      end
    end

    context 'with end date before course end date' do
      subject(:item) { create(:'course_service/item', section:, start_date: nil, end_date: course.end_date - 1.day) }

      it 'has end date of item as effective end date' do
        expect(item.effective_end_date).to eq item.end_date
        expect(item.effective_end_date).not_to eq course.end_date
        expect(item.effective_end_date).not_to be_nil
      end
    end

    context '(event publication)' do
      # Ensure the course and section are created before saving the item.
      let!(:section) { create(:'course_service/section', course:) }
      let!(:item) { build(:'course_service/item', section:) }

      it 'publishes an event for newly created item' do
        # With a new item, the course structure is changed so the course is
        # marked for recalculation, causing an update event to be published.
        expect { item.save! }
          .to have_enqueued_job(PinboardService::SearchCourseUpdateJob)
          .with(kind_of(Hash))
      end

      it 'publishes an event for a destroyed item' do
        item.save!

        # With a destroyed item, the course structure is changed so the course is
        # marked for recalculation, causing an update event to be published.
        expect { item.destroy! }
          .to have_enqueued_job(PinboardService::SearchCourseUpdateJob)
          .with(kind_of(Hash))
      end
    end
  end
end
