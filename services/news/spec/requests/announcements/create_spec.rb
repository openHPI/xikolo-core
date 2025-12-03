# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Announcements: Create', type: :request do
  subject(:resource) { service.rel(:announcements).post(payload).value! }

  let(:service) { Restify.new(:test).get.value! }
  let(:payload) { {} }

  context 'without attributes' do
    it 'responds with 422 Unprocessable Entity' do
      expect { resource }.to raise_error(Restify::UnprocessableEntity)
    end
  end

  context 'with necessary attributes' do
    let(:payload) { {translations: {'en' => english}, author_id:} }
    let(:english) do
      {subject: 'Title', content: 'Text'}
    end
    let(:author_id) { generate(:user_id) }

    it { is_expected.to respond_with :created }

    it 'correctly stores the author and translations' do
      expect { resource }.to change(NewsService::Announcement, :count).from(0).to(1)

      announcement = NewsService::Announcement.last
      expect(announcement.author_id).to eq author_id
      expect(announcement.translations).to eq(
        'en' => {'subject' => 'Title', 'content' => 'Text'}
      )
    end
  end
end
