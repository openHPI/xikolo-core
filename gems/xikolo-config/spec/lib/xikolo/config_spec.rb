# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Xikolo.config' do
  context '#merge' do
    let(:load) { Xikolo.config.merge options }
    context 'value via previous value' do
      after { Xikolo.site = 'unknown' }
      let(:options) { {site: 'batch_update'} }

      it 'should up all keys as config options' do
        expect { load }.to change { Xikolo.site }.from('unknown').to('batch_update')
      end
    end

    context 'with new config values' do
      after { Xikolo.site = 'unknown' }
      let(:options) { {example: true} }

      it 'should up all keys as config options' do
        expect { load }.to change { Xikolo.config.example }.from(nil).to(true)
      end
    end
  end

  context 'default options' do
    subject(:config) { Xikolo.config }

    it 'has #site_name to eq Xikolo' do
      expect(config.site_name).to eq 'Xikolo'
    end

    it 'has #locales to defined globally' do
      expect(config.locales).to eq(
        'available' => %w[de en],
        'default' => 'en'
      )
    end

    it 'has #mailsender undefined' do
      expect(config.mailsender).to eq ''
    end

    it 'has a default UI primary color' do
      expect(config.ui_primary_color).to eq '#FFC04A'
    end
  end

  context '#reload' do
    before do
      Xikolo.base_url = 'https://test.de/'
    end

    it 'should reload all options' do
      expect { Xikolo::Config.reload }.to change { Xikolo.base_url.to_s }.from('https://test.de/').to('https://xikolo.de/')
    end
  end
end
