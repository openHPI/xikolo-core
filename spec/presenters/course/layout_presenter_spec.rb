# frozen_string_literal: true

require 'spec_helper'

describe Course::LayoutPresenter do
  subject(:presenter) { described_class.new course, current_user }

  let(:course_id) { generate(:course_id) }
  let(:course_params) { {id: course_id} }
  let(:course) { create(:course, course_params) }
  let(:user) { create(:'account_service/user') }
  let(:session) { create(:'account_service/session', user:) }
  let(:current_user) { CurrentUser::User.new(session:, context_id: 'root') }
  let(:permissions) { [] }

  before do
    role = create(:'account_service/role', permissions:)
    create(:'account_service/grant', principal: user, role:)
  end

  describe '#nav' do
    it 'has a pinboard item by default' do
      expect(presenter.nav.map(&:text)).to include('Discussions')
    end

    context 'with disabled pinboard' do
      let(:course_params) { super().merge(pinboard_enabled: false) }

      it 'has no pinboard item' do
        expect(presenter.nav.map(&:text)).not_to include('Discussions')
      end
    end
  end

  describe '#unread_announcements' do
    subject(:unread_announcements) { presenter.unread_announcements }

    let!(:unread) { create(:'news_service/news', :published, course_id: course.id) }

    before do
      create(:'news_service/news', :published, :read, course_id: course.id, read_by_users: [user.id])
      create(:'news_service/news', course_id: course.id)
      create(:'news_service/news', :published)
    end

    it { is_expected.to be_empty }

    context 'with a student' do
      let(:permissions) { %w[course.content.access.available] }

      it 'returns the published announcements of the course they have not read' do
        expect(unread_announcements).to contain_exactly(unread)
      end
    end

    context 'with staff accessing the content without enrollment' do
      let(:permissions) { %w[course.content.access] }

      it { is_expected.to be_empty }
    end
  end

  describe '#breadcrumbs' do
    subject(:breadcrumbs) { presenter.breadcrumbs(view_context:) }

    let(:view_context) do
      request = ActionDispatch::TestRequest.create('PATH_INFO' => path)
      request.path_parameters = request.path_parameters.merge(controller:) if controller
      ApplicationController.new.tap {|c| c.request = request }.view_context
    end
    let(:controller) { nil }
    let(:path) { "/learn/#{course.course_code}/progress" }

    it 'starts at the home page and leads to the course' do
      expect(breadcrumbs.pluck(:text).take(3)).to eq [nil, 'Learn', course.title]
      expect(breadcrumbs.third[:url]).to eq "/learn/#{course.course_code}"
      expect(breadcrumbs.first[:aria_label]).to eq 'Home'
    end

    it 'ends at the course page the user is on' do
      expect(breadcrumbs.last).to include(text: 'Progress')
    end

    context 'on the course detail page itself' do
      let(:path) { "/courses/#{course.course_code}" }

      it 'does not repeat it as the last crumb' do
        expect(breadcrumbs.pluck(:text)).to eq [nil, 'Learn', course.title]
      end
    end

    context 'on the course overview page' do
      let(:path) { "/learn/#{course.course_code}/overview" }
      let(:controller) { 'course/syllabus' }

      it 'ends at the learnings' do
        expect(breadcrumbs.last).to include(text: 'Learnings')
      end
    end
  end

  describe '#teacher_nav' do
    subject { super().teacher_nav }

    context 'without user' do
      let(:current_user) { CurrentUser::AnonymousUser.new(context_id: 'root') }

      it { is_expected.to be_empty }
    end

    context 'with a student' do
      it { is_expected.to be_empty }
    end

    context 'with course.dashboard.view' do
      let(:session) { create(:'account_service/session', user: create(:'account_service/user', :admin)) }

      it { is_expected.not_to be_empty }
    end

    context 'with course.course.edit' do
      let(:permissions) { ['course.course.edit'] }

      it { is_expected.not_to be_empty }
    end

    context 'with course.permissions.view' do
      let(:permissions) { ['course.permissions.view'] }

      it { is_expected.to be_empty }

      context 'with course.course.edit' do
        let(:permissions) { ['course.course.edit'] }

        # The permissions item is nested in the course settings item
        it { is_expected.not_to be_empty }
      end
    end

    context 'with course.content.edit' do
      let(:permissions) { ['course.content.edit'] }

      it { is_expected.not_to be_empty }
    end

    context 'with course.enrollment.index' do
      let(:permissions) { ['course.enrollment.index'] }

      it { is_expected.not_to be_empty }
    end

    context 'with quiz.submission.index' do
      let(:permissions) { ['quiz.submission.index'] }

      it { is_expected.not_to be_empty }
    end
  end

  describe '#needs_recalculation?' do
    subject(:needs_recalculation) { presenter.send(:needs_recalculation?) }

    let(:course_params) { {id: course_id, progress_calculated_at: 1.week.ago} }
    let(:course) { create(:course, course_params) }

    before do
      course
    end

    context 'without sufficient permissions' do
      it { is_expected.to be false }
    end

    context 'with sufficient permissions' do
      let(:permissions) { %w[course.course.recalculate] }

      context 'with the course progress not yet calculated' do
        let(:course_params) { super().merge(progress_calculated_at: nil) }

        it { is_expected.to be true }
      end

      context 'for a node not marked for recalculation' do
        it { is_expected.to be false }
      end

      context 'for a node marked for recalculation' do
        before do
          course.node.update! progress_stale_at: 1.hour.ago
        end

        it { is_expected.to be true }
      end

      context 'for legacy courses' do
        let(:course) { create(:course_legacy, course_params) }

        context 'with the course progress not yet calculated' do
          let(:course_params) { super().merge(progress_calculated_at: nil) }

          it { is_expected.to be true }
        end

        context 'when not marked for recalculation' do
          it { is_expected.to be false }
        end

        context 'when marked for recalculation' do
          let(:course_params) { super().merge(progress_stale_at: 1.hour.ago) }

          it { is_expected.to be true }
        end
      end
    end
  end
end
