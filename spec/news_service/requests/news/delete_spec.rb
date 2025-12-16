# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'News: Delete', type: :request do
  subject(:request) { service.rel(:news).delete({id: announcement.id}).value! }

  let(:service) { restify_with_headers(news_service_url).get.value! }

  let!(:announcement) { create(:'news_service/news') }

  it { is_expected.to respond_with :no_content }

  it 'deletes an announcement' do
    expect { request }.to change(NewsService::News, :count).from(1).to(0)
  end

  it 'deletes the correct announcement' do
    expect { request }.to change { NewsService::News.exists? announcement.id }.to(false)
  end
end
