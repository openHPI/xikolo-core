# frozen_string_literal: true

require 'spec_helper'

describe API::BaseController, type: :controller do
  controller do
    def index
      render plain: request.formats.map(&:to_s).join(', ')
    end
  end

  subject(:response) { get :index }

  let(:default_params) { {format:} }

  let(:accept) { nil }
  let(:format) { nil }

  before { request.headers['HTTP_ACCEPT'] = accept }

  describe '#_adjust_accepts' do
    context 'without accept header' do
      it 'adds */* to Rails internal text/html default' do
        expect(response.body).to eq 'text/html, */*'
      end
    end

    context 'with simple accept header (I)' do
      let(:accept) { 'application/json' }

      it 'adds */* to Rails internal text/html default' do
        expect(response.body).to eq 'application/json'
      end
    end

    context 'with simple accept header (2)' do
      let(:accept) { 'application/xml' }

      it 'adds */* to Rails internal text/html default' do
        expect(response.body).to eq 'application/xml'
      end
    end

    context 'with complex accept header (I)' do
      let(:accept) { 'application/json, application/xml' }

      it 'uses all listed mime types' do
        expect(response.body).to eq 'application/json, application/xml'
      end
    end

    context 'with complex accept header (II)' do
      let(:accept) { 'application/json; q=0.8, application/xml' }

      it 'uses all listed mime types' do
        expect(response.body).to eq 'application/xml, application/json'
      end
    end

    context 'with browser like accept header' do
      let(:accept) { 'application/json; q=0.8, application/xml, application/xml+xhtml, */*' }

      it 'uses all listed mime types' do
        expect(response.body).to eq 'text/html, application/xml, application/xml+xhtml, application/json, */*'
      end
    end

    context 'with format parameter' do
      let(:format) { 'json' }

      it 'uses all listed mime types' do
        expect(response.body).to eq 'application/json, */*'
      end
    end

    context 'with format parameter and accept header' do
      let(:format) { 'json' }
      let(:accept) { 'application/xml' }

      it 'uses all listed mime types' do
        expect(response.body).to eq 'application/json, application/xml'
      end
    end
  end
end
