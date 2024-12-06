# frozen_string_literal: true

require 'spec_helper'

describe 'shared/_course_item_header_slim.html.slim', type: :view do
  def rendered_content_for(name)
    view.instance_variable_get(:@view_flow).content[name]
  end

  subject { render_view; rendered_content_for(:page_header_slim) }

  let(:state) { 'preparation' }
  let(:course) do
    Xikolo::Course::Course.new(
      id: SecureRandom.uuid,
      course_code: 'test',
      title: 'My Course Title',
      status: state,
      teacher_text: 'My First Teacher, My Second Teacher'
    )
  end
  let(:user) { Xikolo::Common::Auth::CurrentUser.from_session('permissions' => permissions) }
  let(:permissions) { [] }
  let(:layout) { Course::LayoutPresenter.new(course, user) }
  let(:render_view) { render 'shared/course_item_header_slim', course: layout }

  it { is_expected.to include 'My Course Title' }

  it { is_expected.to include 'My First Teacher, My Second Teacher' }

  it { is_expected.to include 'In preparation' }

  context 'with a available course' do
    let(:state) { 'available' }

    it { is_expected.to include 'Course is available' }
  end

  context 'with upcoming course' do
    let(:state) { 'was_available' }
    let(:start_date) { nil }

    it { is_expected.to include 'Course is finished' }
  end

  context 'with finished course' do
    let(:state) { 'upcoming' }

    it { is_expected.to include 'Course has not yet started' }
  end

  context 'with a archived course' do
    let(:state) { 'archive' }

    it { is_expected.to include 'Self-paced course' }
  end
end
