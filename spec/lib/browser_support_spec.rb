# frozen_string_literal: true

require 'spec_helper'

describe BrowserSupport do
  subject { described_class.new browser }

  let(:browser) { Browser.new user_agent }

  context 'with Chrome 80 on Windows' do
    let(:user_agent) { 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.149 Safari/537.36' }

    it { is_expected.not_to be_unsupported }
    it { is_expected.to be_old }
  end

  context 'with Chrome 119 on Windows' do
    let(:user_agent) { 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36' }

    it { is_expected.not_to be_unsupported }
    it { is_expected.not_to be_old }
  end

  context 'with IE11 on Windows' do
    let(:user_agent) { 'Mozilla/5.0 (Windows NT 10.0; Trident/7.0; rv:11.0) like Gecko' }

    it { is_expected.to be_unsupported }
    it { is_expected.to be_old }
  end

  context 'with Firefox 67 on iPad' do
    let(:user_agent) { 'Mozilla/5.0 (iPad; CPU OS 13_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) FxiOS/67.0 Mobile/15E148 Safari/605.1.15' }

    it { is_expected.not_to be_unsupported }
    it { is_expected.to be_old }
  end

  context 'with Googlebot' do
    let(:user_agent) { 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)' }

    it { is_expected.not_to be_unsupported }
    it { is_expected.not_to be_old }
  end
end
