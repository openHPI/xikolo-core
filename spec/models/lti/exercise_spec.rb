# frozen_string_literal: true

require 'spec_helper'

describe Lti::Exercise, type: :model do
  describe 'attributes' do
    it { is_expected.to accept_values_for(:lti_provider_id, SecureRandom.uuid) }
    it { is_expected.to accept_values_for(:title, 'Title') }
    it { is_expected.not_to accept_values_for(:lti_provider_id, nil) }
  end

  describe '#deleted_provider?' do
    subject { exercise.deleted_provider? }

    let(:exercise) { create(:lti_exercise) }

    it { is_expected.to be false }

    context 'after the corresponding provider has been deleted' do
      before { exercise.provider.destroy }

      it { is_expected.to be true }
    end

    context 'for unsaved models not yet attached to a provider' do
      let(:exercise) { described_class.new }

      it { is_expected.to be false }
    end
  end
end
