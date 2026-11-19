# frozen_string_literal: true

require 'spec_helper'

describe 'openhpi: Homepage', type: :request do
  subject(:homepage) { get '/' }

  before { create(:course, :self_paced) }

  it 'renders successfully' do
    homepage
    expect(response).to have_http_status :ok
  end

  it 'does not show a course list' do
    homepage
    expect(response.body).not_to include 'Current and upcoming courses'
  end

  context 'when signed in with a completed course' do
    let(:user) { create(:'account_service/user') }
    let(:course) { create(:course, :active) }

    before do
      create(:enrollment, course:, user_id: user.id, completed: true)
      sign_in(user:)
    end

    it 'shows the completion badge in the homepage slider' do
      homepage

      card = Capybara.string(response.body).find('.course-card', text: course.title)
      expect(card).to have_text('Completed')
      expect(card).to have_link(course.title, href: "/learn/#{course.course_code}")
    end
  end

  context 'when signed in with an earned achievement' do
    let(:user) { create(:'account_service/user') }
    let(:course) { create(:course, :active, records_released: true, roa_enabled: true, roa_threshold_percentage: 50) }

    before do
      create(:enrollment, course:, user_id: user.id, completed: nil)
      create(:'course_service/course_progress', course:, user_id: user.id,
        main_dpoints: 80, max_dpoints: 100, points_percentage_fpoints: 8000)
      sign_in(user:)
    end

    it 'shows the completion badge from the evaluated enrollment' do
      homepage

      expect(Capybara.string(response.body).find('.course-card', text: course.title)).to have_text('Completed')
    end
  end

  context 'when there are matching courses' do
    before { create_list(:course, 5, :active) }

    it 'renders successfully' do
      homepage
      expect(response).to have_http_status :ok
    end

    it 'always collapses current and upcoming courses under one headline' do
      homepage
      expect(response.body).to include 'Current and upcoming courses'
    end
  end
end
