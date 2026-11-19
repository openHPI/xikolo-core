# frozen_string_literal: true

require 'spec_helper'

describe UserProfilePresenter, type: :presenter do
  let(:user) { create(:'account_service/user') }
  let(:presenter) { described_class.new(nil, UserPresenter.new(user)) }

  before do
    allow(Xikolo::Account::Preferences).to receive(:find).and_return(double(properties: {}))
  end

  describe '#enrolled_courses' do
    subject(:enrolled_courses) { presenter.enrolled_courses.map(&:enrollment) }

    let!(:enrollment) { create(:'course_service/enrollment', user:) }

    context 'with an active enrollment' do
      it { is_expected.to contain_exactly(enrollment) }
    end

    context 'with an inactive (deleted) enrollment' do
      before do
        create(:'course_service/enrollment', user:, deleted: true)
      end

      it { is_expected.to contain_exactly(enrollment) }
    end

    context 'with an enrollment on a deleted course' do
      let!(:deleted_course) { create(:'course_service/course', deleted: true) }

      before do
        create(:'course_service/enrollment', user:, course: deleted_course, deleted: false)
      end

      it { is_expected.to contain_exactly(enrollment) }
    end
  end
end
