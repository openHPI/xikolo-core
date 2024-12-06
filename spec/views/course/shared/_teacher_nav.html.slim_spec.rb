# frozen_string_literal: true

require 'spec_helper'

describe 'course/shared/_teacher_nav.html.slim', type: :view do
  subject { render_view; rendered }

  let(:course) do
    Xikolo::Course::Course.new(
      id: SecureRandom.uuid,
      course_code: 'test',
      title: 'My Course Title',
      status: 'preparation',
      teacher_text: 'My First Teacher, My Second Teacher'
    )
  end
  let(:user) { Xikolo::Common::Auth::CurrentUser.from_session('permissions' => permissions) }
  let(:permissions) { [] }
  let(:layout) { Course::LayoutPresenter.new(course, user) }
  let(:render_view) { render 'course/shared/teacher_nav', teacher_nav: layout.teacher_nav }

  describe 'teacher menu' do
    context 'as teacher' do
      let(:permissions) { ['course.course.edit'] }

      it { is_expected.to include 'Course Administration' }
    end

    context 'as non-teacher' do
      it { is_expected.not_to include 'Course Administration' }
    end
  end
end
