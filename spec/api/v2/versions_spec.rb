# frozen_string_literal: true

require 'spec_helper'

describe 'API: Versions' do
  describe '#supported_versions' do
    subject(:versions) { Xikolo::API.supported_versions }

    # TIMEBOMB TEST
    # If this test starts failing, the supported API versions should be cleaned
    # up. Do not forget to remove version-specific code from API endpoints.
    it 'does not contain expired versions' do
      expect(versions).to all(satisfy do |version|
        version.expiry_date.nil? || version.expiry_date >= 2.weeks.ago
      end)
    end
  end
end
