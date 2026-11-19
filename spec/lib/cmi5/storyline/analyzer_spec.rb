# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cmi5::Storyline::Analyzer do
  subject(:analyzer) { described_class.new(cmi5_item) }

  let(:cmi5_item) { create(:cmi5_item) }

  before { Cmi5ItemUnzipJob.perform_now(cmi5_item) }

  describe '#to_h' do
    subject(:metadata) { analyzer.to_h }

    it 'detects the player dimensions' do
      expect(metadata).to eq(player_width: 1940, player_height: 1151)
    end
  end

  context 'with a package that is not a Storyline package' do
    let(:cmi5_item) do
      create(
        :cmi5_item,
        package: Rack::Test::UploadedFile.new(
          Rails.root.join('spec/fixtures/files/cmi5_test_au.zip')
        )
      )
    end

    it 'returns unknown values instead of guessing' do
      expect(analyzer.to_h).to eq(player_width: nil, player_height: nil)
    end
  end
end
