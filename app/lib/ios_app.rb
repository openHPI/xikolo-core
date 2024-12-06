# frozen_string_literal: true

module IosApp
  class << self
    def configured?
      config.is_a? Hash
    end

    def id
      config['id']
    end

    def name
      config['name']
    end

    def campaign?
      config['provider_id'] && config['campaign_token']
    end

    def campaign_params
      "pt=#{config['provider_id']}&ct=#{config['campaign_token']}&" if campaign?
    end

    def smart_app_banner
      tag.meta(name: 'apple-itunes-app', content: "app-id=#{id}")
    end

    def app_store_url
      "https://itunes.apple.com/app/id#{id}?#{campaign_params}mt=8"
    end

    private

    include ActionView::Helpers::TagHelper

    def config
      Xikolo.config.ios_app
    end
  end
end
