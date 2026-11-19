# frozen_string_literal: true

require 'spec_helper'

describe Course::CourseDetailsPresenter do
  subject(:presenter) { described_class.build(course, [], user) }

  let(:course_id) { generate(:course_id) }
  let(:course_params) { {id: course_id, start_date: 1.week.ago} }
  let(:course) { create(:'course_service/course', course_params) }
  let(:session) { create(:'account_service/session') }
  let(:user) { CurrentUser::User.new(session:, context_id: 'root') }

  let(:previewable_items_stub) do
    Stub.request(
      :course, :get, '/items',
      query: {course_id:, open_mode: true}
    ).to_return Stub.json([])
  end

  before do
    previewable_items_stub
  end

  describe '#enrollment_count' do
    let(:count) { 499 }
    let(:user) { CurrentUser::AnonymousUser.new(context_id: 'root') }

    before do
      stats = instance_double(Course::EnrollmentsStatistics, current: count)
      allow(course).to receive(:stats).and_return(instance_double(Course::Statistics, enrollments: stats))
    end

    it 'hides counts below 500' do
      expect(presenter.enrollment_count).to be_nil
    end

    context 'at the visibility threshold' do
      let(:count) { 500 }

      it 'returns the count' do
        expect(presenter.enrollment_count).to eq 500
      end
    end

    context 'with permission to see smaller counts' do
      let(:user) { CurrentUser::User.new(session:, context_id: 'root') }

      before do
        role = create(:'account_service/role', permissions: %w[course.enrollment_counter.view])
        create(:'account_service/grant', principal: session.user, role:)
      end

      it 'returns the count' do
        expect(presenter.enrollment_count).to eq 499
      end
    end

    context 'with an external course' do
      let(:course_params) { super().merge(external_course_url: 'https://example.org/course') }
      let(:count) { 500 }

      it 'hides the count' do
        expect(presenter.enrollment_count).to be_nil
      end
    end
  end

  describe '#meta_tags' do
    # A distinct instance so we can stub its `visual_url` collaborator without
    # stubbing the shared `subject` (which RSpec/SubjectStub forbids).
    let(:instance) { described_class.build(course, [], user) }
    let(:og_image) { 'https://s3.example.com/courses/123/visual.png' }

    before do
      allow(instance).to receive(:visual_url).and_return(visual)
    end

    context 'with a usable visual URL' do
      let(:visual) { og_image }

      it 'sets og:image and og:image:secure_url to the visual URL' do
        og = instance.meta_tags[:og]

        expect(og[:image]).to eq(og_image)
        expect(og['image:secure_url']).to eq(og_image)
      end
    end

    context 'with the literal "null" string' do
      let(:visual) { 'null' }

      it 'omits the og:image and og:image:secure_url tags' do
        og = instance.meta_tags[:og]

        expect(og[:image]).to be_nil
        expect(og['image:secure_url']).to be_nil
      end
    end

    context 'with the "NULL" string (case-insensitive)' do
      let(:visual) { 'NULL' }

      it 'omits the og:image and og:image:secure_url tags' do
        og = instance.meta_tags[:og]

        expect(og[:image]).to be_nil
        expect(og['image:secure_url']).to be_nil
      end
    end

    context 'with a blank visual URL' do
      let(:visual) { nil }

      it 'omits the og:image and og:image:secure_url tags' do
        og = instance.meta_tags[:og]

        expect(og[:image]).to be_nil
        expect(og['image:secure_url']).to be_nil
      end
    end
  end

  describe '#open_mode?' do
    let(:user) { CurrentUser::AnonymousUser.new(context_id: 'root') }

    it 'is not in open mode when feature is disabled' do
      AccountService::Feature.find_by!(name: 'open_mode').destroy!

      expect(presenter).not_to be_open_mode
    end

    context 'with open_mode feature' do
      it { is_expected.not_to be_open_mode }
    end

    context 'with previewable items' do
      let(:previewable_items_stub) do
        Stub.request(
          :course, :get, '/items',
          query: {course_id:, open_mode: true}
        ).to_return Stub.json([{id: SecureRandom.uuid}])
      end

      it 'is not in open mode when feature is disabled' do
        AccountService::Feature.find_by!(name: 'open_mode').destroy!

        expect(presenter).not_to be_open_mode
      end

      context 'with open_mode feature' do
        it { is_expected.to be_open_mode }

        context 'with a hidden course' do
          let(:course_params) { super().merge(placement: []) }

          it { is_expected.not_to be_open_mode }
        end

        context 'with an invite-only course' do
          let(:course_params) { super().merge(invite_only: true) }

          it { is_expected.not_to be_open_mode }
        end
      end
    end
  end

  describe '#access_allowed?' do
    let(:permissions) { [] }
    let(:was_available) { true }

    before do
      role = create(:'account_service/role', permissions:)
      create(:'account_service/grant', principal: session.user, role:)
      allow(course).to receive(:was_available?).and_return(was_available)
    end

    it { is_expected.to be_access_allowed }

    context 'with never available course' do
      let(:was_available) { false }

      it { is_expected.not_to be_access_allowed }

      context 'with course.content.access permission' do
        let(:permissions) { ['course.content.access'] }

        it { is_expected.to be_access_allowed }
      end

      context 'when not logged in' do
        let(:user) { CurrentUser::AnonymousUser.new(context_id: 'root') }

        it { is_expected.not_to be_access_allowed }
      end
    end

    context 'with external_course_url' do
      let(:course_params) { super().merge(external_course_url: 'http://test') }

      it { is_expected.not_to be_access_allowed }

      context 'with course.content.access permission' do
        let(:permissions) { ['course.content.access'] }

        it { is_expected.to be_access_allowed }
      end
    end
  end
end
