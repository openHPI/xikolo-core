# frozen_string_literal: true

require 'spec_helper'

describe 'course/shared/_teacher_nav.html.slim', type: :view do
  subject { render_view; rendered }

  let(:course) do
    create(:'course_service/course',
      id: SecureRandom.uuid,
      course_code: 'test',
      title: 'My Course Title',
      published: false)
  end
  let(:current_user) { CurrentUser::User.new(context_id: 'root', session: create('account_service/session', user:)) }
  let(:layout) { Course::LayoutPresenter.new(course, current_user) }
  let(:render_view) { render 'course/shared/teacher_nav', teacher_nav: layout.teacher_nav }

  describe 'teacher menu' do
    context 'as teacher' do
      let(:user) { create(:'account_service/user', :admin) }

      it { is_expected.to include 'Course Administration' }
    end

    context 'as non-teacher' do
      let(:user) { create(:'account_service/user') }

      it { is_expected.not_to include 'Course Administration' }
    end
  end
end
