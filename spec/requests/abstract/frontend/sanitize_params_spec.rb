# frozen_string_literal: true

require 'spec_helper'

class DummyController < Abstract::FrontendController
  def index
    render json: params.except(:controller, :action)
  end
end

describe 'Abstract: Frontend: Base: Sanitize Params', type: :request do
  subject(:action) { get '/dummy', params: }

  around do |example|
    Rails.application.routes.draw do
      get '/dummy', to: 'dummy#index'
    end
    example.run
  ensure
    Rails.application.reload_routes!
  end

  context 'when a string parameter contains a null-byte character' do
    let(:params) do
      {
        unicode: "\u0000invalid",
        unicode_empty: "\u0000",
        hex: "\x00invalid",
        percent_encoded: '%00invalid',
        double_encoded: 'invalid%2500',
      }
    end

    it 'sanitizes all affected parameters' do
      action
      expect(response.parsed_body).to be_empty
    end
  end
end
