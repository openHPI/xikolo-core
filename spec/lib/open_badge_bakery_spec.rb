# frozen_string_literal: true

require 'spec_helper'
require 'open_badge_bakery'

describe OpenBadgeBakery do
  describe '#bake' do
    subject(:badge) do
      described_class.new(
        assertion,
        image_url,
        Rails.application.secrets.open_badge_private_key
      ).bake
    end

    let(:assertion) do
      {
        id: 'abcdefghijklm1234567898765',
        recipient: {
          identity: 'sha256$a1b2c3d4e5f6g7h8i9a1b2c3d4e5f6g7h8i9a1b2c3d4e5f6g7h8i9',
          type: 'email',
          hashed: true,
        },
        badge: 'http://issuersite.org/badge-class.json',
        verify: {
          url: 'http://issuersite.org/public-key.pem',
          type: 'signed',
        },
        issuedOn: 1_403_120_715,
      }
    end
    let(:image_url) { 'http://test.host/badge_template.png' }

    before do
      xi_config file_fixture('badge_config.yml').read

      stub_request(:get, image_url)
        .to_return(
          body: Rails.root.join('spec/support/files/certificate/badge_template.png').open,
          status: 200,
          headers: {'Content-Type' => 'image/png'}
        )
    end

    it 'bakes the assertion into the PNG' do
      # Extract and verify signed assertion
      ds = ChunkyPNG::Datastream.from_blob(badge)
      signed_assertion = ds.other_chunks.find do |c|
        c.type == 'iTXt' && c.keyword == 'openbadges'
      end.text

      expect(
        verify_assertion(signed_assertion, Xikolo.config.open_badges['public_key'])
      ).to be_truthy
    end
  end
end
