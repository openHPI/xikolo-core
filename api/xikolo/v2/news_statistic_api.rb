# frozen_string_literal: true

module Xikolo
  module V2
    class NewsStatisticAPI < Grape::API::Instance
      namespace 'news_statistics' do
        mount Endpoint::ListNewsStatistics
      end
    end
  end
end
