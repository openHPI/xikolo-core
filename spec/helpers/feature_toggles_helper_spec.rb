# frozen_string_literal: true

require 'spec_helper'

class TestClass
  include FeatureTogglesHelper

  class << self
    attr_accessor :enabled_features
  end

  def current_user
    Xikolo::Common::Auth::CurrentUser.from_session('features' => self.class.enabled_features, 'user' => {'anonymous' => false})
  end
end

describe FeatureTogglesHelper, type: :helper do
  subject { helper }

  describe '#feature?' do
    let(:feature_name) { 'the_feature' }
    let(:enabled_features) { {} }

    before do
      TestClass.enabled_features = enabled_features
    end

    describe 'checking for a generic feature' do
      subject { TestClass.new.feature? feature_name }

      context 'when the feature is not enabled' do
        it { is_expected.to be false }
      end

      context 'when the feature is enabled' do
        let(:enabled_features) { {feature_name => nil} }

        it { is_expected.to be true }
      end

      context 'when the feature is enabled with value (such as a test group)' do
        let(:enabled_features) { {feature_name => '3'} }

        it { is_expected.to be true }
      end
    end

    describe 'checking for a feature with value (e.g. a user test)' do
      subject { TestClass.new.feature? feature_name, *possible_values }

      let(:possible_values) { [1, 2] }

      context 'when the feature is not enabled' do
        it { is_expected.to be false }
      end

      context 'when the feature is enabled, but has no value' do
        let(:enabled_features) { {feature_name => nil} }

        it { is_expected.to be false }
      end

      context 'when the feature is enabled, but has a different value' do
        let(:enabled_features) { {feature_name => '3'} }

        it { is_expected.to be false }
      end

      context 'when the feature is enabled with one of the allowed values' do
        let(:enabled_features) { {feature_name => '1'} }

        it { is_expected.to be true }
      end
    end
  end
end
