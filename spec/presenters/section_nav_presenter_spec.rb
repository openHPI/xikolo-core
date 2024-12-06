# frozen_string_literal: true

require 'spec_helper'

describe SectionNavPresenter, type: :component do
  subject(:presenter) { described_class.new(user:, view_context:, course:) }

  let(:sections) { [] }
  let(:course_resource) { build(:'course:course') }
  let(:course) { Xikolo::Course::Course.new course_resource }
  let(:view_context) { vc_test_controller.view_context }

  let(:anonymous) { Xikolo::Common::Auth::CurrentUser.from_session({}) }
  let(:user_id) { generate(:user_id) }
  let(:permissions) { [] }
  let(:user) do
    Xikolo::Common::Auth::CurrentUser.from_session(
      'permissions' => permissions,
      'user_id' => user_id,
      'user' => {'anonymous' => false}
    )
  end

  before do
    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, '/sections', query: {course_id: course.id})
      .to_return Stub.json(sections)

    course.sections
    Acfs.run
  end

  describe '#table_of_contents' do
    subject(:rendered_output) { render_inline(presenter.table_of_contents) }

    context 'with course sections' do
      let(:sections) do
        [
          build(:'course:section', title: 'A Section'),
          build(:'course:section', title: 'Unpublished section', published: false),
        ]
      end

      it 'has a syllabus link by default' do
        expect(rendered_output).to have_link('Overview')
      end

      it 'has a link to the sections' do
        expect(rendered_output).to have_link('A Section')
      end

      it 'does not include unpublished sections' do
        expect(rendered_output).to have_link('Overview')
        expect(rendered_output).to have_no_link('Unpublished section')
      end

      it 'shows no discussion link on inactive section' do
        expect(rendered_output).to have_link('Overview')
        expect(rendered_output).to have_no_link('Discussions')
      end
    end

    context 'user permissions' do
      let(:sections) do
        [
          build(:'course:section', title: 'Section with passed end date',
            effective_start_date: 2.days.ago,
            effective_end_date: 1.day.ago),
          build(:'course:section', title: 'Section not yet available',
            effective_start_date: 2.days.from_now,
            effective_end_date: 1.day.from_now),
        ]
      end

      context 'without course content permission' do
        it 'does not link to locked sections' do
          expect(rendered_output).to have_link('Overview')
          expect(rendered_output).to have_no_link('Section with passed end date')
          expect(rendered_output).to have_no_link('Section not yet available')
        end
      end

      context 'with course content permission' do
        let(:permissions) { ['course.content.access'] }

        it 'links to locked sections' do
          expect(rendered_output).to have_link('Overview')
          expect(rendered_output).to have_link('Section with passed end date')
          expect(rendered_output).to have_link('Section not yet available')
        end
      end
    end
  end
end
