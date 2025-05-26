# frozen_string_literal: true

require 'spec_helper'

describe PinboardPresenter, type: :presenter do
  subject(:presenter) { described_class.new(**context) }

  let(:context) { {course:} }

  let(:course_id) { '81e01000-3300-4444-a001-000000000001' }
  let(:course) { Xikolo::Course::Course.new(id: course_id, course_code: 'the_course') }
  let(:section_id) { '81e01000-3300-4444-a002-000000000001' }
  let(:short_section_id) { '3X4peCYbbcr6QSYXoifvl7' } # base62 form of above UUID
  let(:section) { build(:'course:section', id: section_id, title: 'Week 3') }
  let(:thread_id) { '81e01000-3500-4444-a001-000000000001' }
  let(:thread) { Xikolo::Pinboard::Question.new(id: thread_id, title: 'What can I ask?') }

  describe '#breadcrumbs' do
    describe '#for_list' do
      subject(:crumbs) { presenter.breadcrumbs.for_list }

      it 'yields all discussions' do
        expect {|b| crumbs.each_level(&b) }.to yield_successive_args(
          ['/courses/the_course/pinboard', 'All discussions']
        )
      end

      context 'in a course section' do
        let(:context) { super().merge(section:) }

        it 'yields all discussions and the section' do
          expect {|b| crumbs.each_level(&b) }.to yield_successive_args(
            ['/courses/the_course/pinboard', 'All discussions'],
            ["/courses/the_course/sections/#{short_section_id}/pinboard", 'Week 3']
          )
        end
      end

      context 'in the technical issues section' do
        let(:context) { super().merge(section: nil, technical_issues: true) }

        it 'yields all discussions and the pseudo-section' do
          expect {|b| crumbs.each_level(&b) }.to yield_successive_args(
            ['/courses/the_course/pinboard', 'All discussions'],
            ['/courses/the_course/sections/technical_issues/pinboard', 'Technical Issues']
          )
        end
      end
    end

    describe '#for_thread' do
      subject(:crumbs) { presenter.breadcrumbs.for_thread(thread) }

      it 'yields all discussions and the thread' do
        expect {|b| crumbs.each_level(&b) }.to yield_successive_args(
          ['/courses/the_course/pinboard', 'All discussions'],
          ["/courses/the_course/question/#{thread_id}", 'What can I ask?']
        )
      end

      context 'in a course section' do
        let(:context) { super().merge(section:) }

        it 'yields all discussions, the section and the thread' do
          expect {|b| crumbs.each_level(&b) }.to yield_successive_args(
            ['/courses/the_course/pinboard', 'All discussions'],
            ["/courses/the_course/sections/#{short_section_id}/pinboard", 'Week 3'],
            ["/courses/the_course/sections/#{short_section_id}/question/#{thread_id}", 'What can I ask?']
          )
        end
      end

      context 'in the technical issues section' do
        let(:context) { super().merge(section: nil, technical_issues: true) }

        it 'yields all discussions, the pseudo-section and the thread' do
          expect {|b| crumbs.each_level(&b) }.to yield_successive_args(
            ['/courses/the_course/pinboard', 'All discussions'],
            ['/courses/the_course/sections/technical_issues/pinboard', 'Technical Issues'],
            ["/courses/the_course/sections/technical_issues/question/#{thread_id}", 'What can I ask?']
          )
        end
      end
    end
  end

  describe '(locking)' do
    context 'in a course forum' do
      it 'allows posting by default' do
        expect(presenter.open?).to be true
        expect(presenter.lock_reason).to be_nil
      end

      it 'does not allow posting when the course pinboard was locked' do
        course.forum_is_locked = true

        expect(presenter.open?).to be false
        expect(presenter.lock_reason).to include 'The discussions for this course are read-only.'
      end
    end

    context 'in a course section' do
      let(:context) { super().merge(section:) }

      it 'allows posting by default' do
        expect(presenter.open?).to be true
        expect(presenter.lock_reason).to be_nil
      end

      it 'does not allow posting when the course pinboard was locked' do
        course.forum_is_locked = true

        expect(presenter.open?).to be false
        expect(presenter.lock_reason).to include 'The discussions for this course are read-only.'
      end

      it 'does not allow posting when the section pinboard was locked' do
        section['pinboard_closed'] = true

        expect(presenter.open?).to be false
        expect(presenter.lock_reason).to include 'The discussions for the section "Week 3" are read-only.'
      end

      it 'does not allow posting when both the course and section pinboards were locked' do
        course.forum_is_locked = true
        section['pinboard_closed'] = true

        expect(presenter.open?).to be false
        expect(presenter.lock_reason).to include 'The discussions for this course are read-only.'
      end
    end

    context 'in the technical issues section' do
      let(:context) { super().merge(section: nil, technical_issues: true) }

      it 'allows posting by default' do
        expect(presenter.open?).to be true
        expect(presenter.lock_reason).to be_nil
      end

      it 'does not allow posting when the course pinboard was locked' do
        course.forum_is_locked = true

        expect(presenter.open?).to be false
        expect(presenter.lock_reason).to include 'The discussions for this course are read-only.'
      end

      # "Technical issues" can not be locked on its own
    end
  end

  describe 'filters' do
    context 'in a course forum with no available filters' do
      let(:filters) { {tags: nil, sections: nil} }
      let(:context) { super().merge(section:, filters:) }

      it 'does not have tags and section filters' do
        expect(presenter.section_filter).to be_nil
        expect(presenter.tags_filter).to be_nil
      end
    end

    context 'in a course forum with filters' do
      let(:filters) { {tags: [%w[Tag 123]], sections: [['All discussions', '/'], ['Technical Issues', '/issues'], ['Week 3', '/section/3']]} }
      let(:context) { super().merge(section:, filters:) }

      it 'has the right filters' do
        expect(presenter.tags_filter).to eq [%w[Tag 123]]
        expect(presenter.section_filter).to eq [['All discussions', '/'], ['Technical Issues', '/issues'], ['Week 3', '/section/3']]
      end

      it 'shows the right selected section' do
        expect(presenter.current_section).to eq '/section/3'
      end
    end

    context 'in the technical issues section' do
      let(:filters) { {tags: [%w[Tag 123]], sections: [['All discussions', '/'], ['Technical Issues', '/issues'], ['Week 3', '/section/3']]} }
      let(:context) { super().merge(technical_issues: true, filters:) }

      it 'shows the right selected section' do
        expect(presenter.current_section).to eq '/issues'
      end
    end
  end
end
