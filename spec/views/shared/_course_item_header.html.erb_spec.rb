# frozen_string_literal: true

require 'spec_helper'

describe 'shared/_course_item_header.html.erb', type: :view do
  def rendered_content_for(name)
    view.instance_variable_get(:@view_flow).content[name]
  end

  subject(:header) do
    render_view
    rendered_content_for(:page_header)
  end

  let(:course) { create(:'course_service/course', title: 'My Course Title', teacher_ids: [teacher.id]) }
  let(:teacher) { create(:'course_service/teacher', name: 'My First Teacher') }
  let(:session) { create(:'account_service/session') }
  let(:user) { CurrentUser::User.new(session:, context_id: 'root') }
  let(:permissions) { [] }
  let(:layout) { Course::LayoutPresenter.new(course, user) }
  let(:item) { nil }
  let(:render_view) { render 'shared/course_item_header', course: layout, item: }

  before do
    role = create(:'account_service/role', permissions:)
    create(:'account_service/grant', principal: session.user, role:)
  end

  it { is_expected.to include 'My Course Title' }

  it 'leads the user through the course' do
    expect(header).to have_css('.x-breadcrumbs') do |breadcrumbs|
      expect(breadcrumbs).to have_link('My Course Title', href: course_path(course.course_code))
    end
  end

  context 'without an item' do
    it 'shows no item header' do
      expect(header).not_to include 'x-card'
    end
  end
end
