# frozen_string_literal: true

require 'spec_helper'

describe Course::CourseDetailsPresenter do
  subject(:presenter) { described_class.build(course, [], user) }

  let(:course_id) { generate(:course_id) }
  let(:course_params) { {id: course_id, start_date: 1.week.ago, hidden: false} }
  let(:course) { Xikolo::Course::Course.new course_params }
  let(:features) { {} }
  let(:permissions) { [] }
  let(:anonymous) { false }
  let(:user) do
    Xikolo::Common::Auth::CurrentUser.from_session(
      'features' => features,
      'permissions' => permissions,
      'user' => {'anonymous' => anonymous},
      'masqueraded' => false
    )
  end

  let(:previewable_items_stub) do
    Stub.request(
      :course, :get, '/items',
      query: {course_id:, open_mode: true}
    ).to_return Stub.json([])
  end

  before do
    previewable_items_stub
  end

  describe '#open_mode?' do
    let(:anonymous) { true }

    it { is_expected.not_to be_open_mode }

    context 'with open_mode feature' do
      let(:features) { {'open_mode' => true} }

      it { is_expected.not_to be_open_mode }
    end

    context 'with previewable items' do
      let(:previewable_items_stub) do
        Stub.request(
          :course, :get, '/items',
          query: {course_id:, open_mode: true}
        ).to_return Stub.json([{id: SecureRandom.uuid}])
      end

      it { is_expected.not_to be_open_mode }

      context 'with open_mode feature' do
        let(:features) { {'open_mode' => true} }

        it { is_expected.to be_open_mode }

        context 'with a hidden course' do
          let(:course_params) { super().merge(hidden: true) }

          it { is_expected.not_to be_open_mode }
        end

        context 'with an invite-only course' do
          let(:course_params) { super().merge(invite_only: true) }

          it { is_expected.not_to be_open_mode }
        end
      end
    end
  end
end
