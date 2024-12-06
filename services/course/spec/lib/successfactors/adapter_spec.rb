# frozen_string_literal: true

require 'spec_helper'

describe Successfactors::Adapter do
  subject(:sync) do
    described_class
      .new(
        provider_attrs[:name],
        course,
        provider_attrs[:config]
      )
      .sync
  end

  let(:course) { create(:course, :active) }
  let(:provider_attrs) { attributes_for(:course_provider, :successfactors) }

  # prevent callback on course creation through FactoryBot
  before { allow_any_instance_of(Course).to receive(:sync_providers) } # rubocop:disable RSpec/AnyInstance

  describe '#sync' do
    context 'with incomplete configuration' do
      let(:provider_attrs) do
        super().merge(
          config: {client_id: 'abc', client_secret: '123'}.stringify_keys
        )
      end

      it 'raises an error' do
        expect { sync }.to raise_error(
          Successfactors::ConfigError,
          'SuccessFactors config not sufficient (missing options: ' \
          'base_url, user_id, company_id, provider_id, launch_url_template)'
        )
      end
    end
  end
end
