# frozen_string_literal: true

require 'spec_helper'

describe Course::FeaturedCourse, type: :component do
  subject(:component) do
    described_class.new queried_course, enrollment:
  end

  let(:course) { create(:course, :active) }
  let(:queried_course) { Catalog::Course.find(course.id) }
  let(:user_id) { generate(:user_id) }
  let(:enrollment) { nil }

  it 'shows information about the course' do
    render_inline(component)

    expect(page).to have_link 'Details'
    expect(page).to have_link 'Enroll'
    expect(page).to have_link 'MOOC on topic'
    expect(page).to have_content 'Abstract text'
  end

  context 'with the user enrolled in the course' do
    let(:enrollment) { Course::Enrollment.new(course:, user_id:) }

    it 'allows to resume the course' do
      render_inline(component)

      expect(page).to have_link 'Resume'
      expect(page).to have_no_link 'Enroll'
    end
  end

  context 'when the course abstract contains markdown' do
    let(:course) { create(:course, :active, abstract: '**Abstract text**') }

    it 'renders sanitized content' do
      render_inline(component)

      expect(page).to have_content 'Abstract text'
      expect(page).to have_no_content '**Abstract text**'
    end
  end
end
