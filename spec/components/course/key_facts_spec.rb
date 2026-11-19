# frozen_string_literal: true

require 'spec_helper'

describe Course::KeyFacts, type: :component do
  subject(:component) { described_class.new(presenter) }

  let(:user) { CurrentUser::AnonymousUser.new(context_id: 'root') }
  let(:course) { create(:'course_service/course', lang: 'de', **course_attrs) }
  let(:course_attrs) { {} }
  let(:presenter) { CourseInfoPresenter.build(course, user) }

  it 'shows the course language' do
    render_inline(component)

    expect(page).to have_css 'abbr[title="Deutsch"]', text: 'DE'
  end

  it 'shows that a certificate is offered' do
    render_inline(component)

    expect(page).to have_text 'Certificate'
  end

  context 'without certificates' do
    let(:course_attrs) { {roa_enabled: false, cop_enabled: false} }

    it 'does not mention a certificate' do
      render_inline(component)

      expect(page).to have_no_text 'Certificate'
    end
  end

  context 'with a level classifier' do
    let(:level) { create(:'course_service/cluster', id: 'level', visible: true) }
    let(:topic) { create(:'course_service/cluster', id: 'topic', visible: true) }
    let(:course_attrs) do
      {classifiers: [
        create(:'course_service/classifier', cluster: level, translations: {'en' => 'Expert'}),
        create(:'course_service/classifier', cluster: topic, translations: {'en' => 'AI'}),
      ]}
    end

    it 'shows the level' do
      render_inline(component)

      expect(page).to have_css 'li', text: 'Expert'
      expect(page).to have_no_text 'AI'
    end
  end
end
