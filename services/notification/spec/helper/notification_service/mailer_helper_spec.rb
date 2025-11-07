# frozen_string_literal: true

require 'spec_helper'

describe NotificationService::MailerHelper, type: :helper do
  describe 'locale_string_from' do
    subject(:string) { helper.locale_string_from params }

    let(:params) { {'en' => 'english', 'de' => 'german'} }

    context 'with correct locale' do
      before { allow(I18n).to receive(:locale).and_return('de') }

      it { is_expected.to eq 'german' }
    end

    context 'with fallback english' do
      it { is_expected.to eq 'english' }
    end

    context 'with fallback' do
      let(:params) { {'de' => 'german'} }

      it { is_expected.to eq 'german' }
    end

    context 'with an empty translation' do
      let(:params) { {'en' => nil, 'de' => 'german'} }

      it 'uses the first non-empty one' do
        expect(string).to eq 'german'
      end
    end
  end
end
