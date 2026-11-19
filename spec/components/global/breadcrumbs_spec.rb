# frozen_string_literal: true

require 'spec_helper'

describe Global::Breadcrumbs, type: :component do
  subject(:component) { described_class.new(**props) }

  let(:items) do
    [
      {url: '/courses', text: 'Courses'},
      {url: '/courses/42', text: 'My Course'},
    ]
  end
  let(:props) { {items:} }

  it 'renders a link for each level' do
    render_inline(component)

    expect(rendered_content).to have_link('Courses', href: '/courses')
    expect(rendered_content).to have_link('My Course', href: '/courses/42')
  end

  context 'with an icon' do
    let(:items) do
      [{url: '/', icon: '<span>Home</span>'.html_safe, aria_label: 'Home'}]
    end

    it 'renders the icon' do
      render_inline(component)

      expect(rendered_content).to have_link('Home', href: '/')
    end
  end
end
