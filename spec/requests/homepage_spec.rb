# frozen_string_literal: true

require 'spec_helper'

describe 'openhpi: Homepage', type: :request do
  subject(:homepage) { get '/' }

  before { create(:course, :archived) }

  it 'renders successfully' do
    homepage
    expect(response).to have_http_status :ok
  end

  it 'does not show a course list' do
    homepage
    expect(response.body).not_to include 'Current and upcoming courses'
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
