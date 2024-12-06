# frozen_string_literal: true

require 'spec_helper'

describe Proctoring do
  subject { described_class }

  describe '#enabled?' do
    subject { super().enabled? }

    context 'w/ secrets in secrets.yml' do
      it { is_expected.to be true }
    end

    context 'w/ incomplete local configuration' do
      before do
        xi_config <<~YML
          proctoring: {}
        YML
      end

      it { is_expected.to be false }
    end
  end
end
