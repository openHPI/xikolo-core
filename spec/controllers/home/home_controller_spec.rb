# frozen_string_literal: true

require 'spec_helper'

describe Home::HomeController, type: :controller do
  describe '#index' do
    subject { get :index }

    context 'with news available' do
      before do
        Stub.request(:news, :get, '/news', query: {
          global: true,
          language: 'en',
          only_homepage: true,
          per_page: 4,
          published: true,
        }).to_return Stub.json([])
      end

      it { is_expected.to have_http_status :ok }
    end

    context 'with news unavailable' do
      before do
        Stub.enable :news
        Stub.request(:news, :get, '/').to_return status: 0
      end

      it { is_expected.to have_http_status :ok }
    end

    context 'without news service' do
      it { is_expected.to have_http_status :ok }
    end
  end
end
