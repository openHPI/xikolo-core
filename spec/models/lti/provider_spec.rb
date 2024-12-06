# frozen_string_literal: true

require 'spec_helper'

describe Lti::Provider, type: :model do
  describe 'attributes' do
    it { is_expected.to accept_values_for(:consumer_key, SecureRandom.hex) }
    it { is_expected.to accept_values_for(:domain, 'localhost:5321') }
    it { is_expected.to accept_values_for(:name, 'Provider') }
    it { is_expected.to accept_values_for(:shared_secret, SecureRandom.hex) }
    it { is_expected.to accept_values_for(:presentation_mode, 'frame', 'pop-up', 'window') }
    it { is_expected.to accept_values_for(:course_id, SecureRandom.uuid, nil) }
    it { is_expected.to accept_values_for(:privacy, 'anonymized', 'pseudonymized', 'unprotected') }

    it { is_expected.not_to accept_values_for(:consumer_key, '') }
    it { is_expected.not_to accept_values_for(:domain, '') }
    it { is_expected.not_to accept_values_for(:domain, 'foo') }
    it { is_expected.not_to accept_values_for(:name, '') }
    it { is_expected.not_to accept_values_for(:shared_secret, '') }
    it { is_expected.not_to accept_values_for(:presentation_mode, '', nil, '     ') }
    it { is_expected.not_to accept_values_for(:privacy, 'free', 'closed', nil) }
  end

  describe 'deleting' do
    subject(:deletion) { provider.destroy }

    let(:provider) { create(:lti_provider) }

    context 'with exercises' do
      before { create_list(:lti_exercise, 3, provider:) }

      # This is important so that course items using these LTI exercises do not
      # break in ugly ways. Instead, we can show a friendly message that the
      # provider no longer works.
      it 'leaves the orphaned exercises intact' do
        expect { deletion }.not_to change(Lti::Exercise, :count)
      end
    end
  end
end
