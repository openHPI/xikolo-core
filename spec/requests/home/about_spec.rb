# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Home: About: Show', type: :request do
  describe 'as anonymous user' do
    it 'renders the page' do
      get '/about'

      expect(response).to have_http_status :ok
    end

    it 'sets the localized page title' do
      get '/about'

      title = I18n.t(:'header.meta_tags.about.title', site_name: Xikolo.config.site_name)
      expect(response.body).to include("<title>#{title}</title>")
    end
  end
end
