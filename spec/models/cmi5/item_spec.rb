# frozen_string_literal: true

require 'spec_helper'

describe Cmi5::Item, type: :model do
  subject(:cmi5_item) { create(:cmi5_item) }

  describe '#data_script_file' do
    it 'returns the file at the Storyline data script path' do
      data_script = cmi5_item.files.create!(file_path: 'html5/data/js/data.js')
      cmi5_item.files.create!(file_path: 'html5/data/js/other.js')

      expect(cmi5_item.data_script_file).to eq(data_script)
    end

    it 'returns nil when no Storyline data script is present' do
      cmi5_item.files.create!(file_path: 'html5/lib/scripts.js')

      expect(cmi5_item.data_script_file).to be_nil
    end
  end

  describe '#player_aspect_ratio' do
    it 'is the player width divided by its height' do
      cmi5_item.update!(player_width: 1940, player_height: 1151)

      expect(cmi5_item.player_aspect_ratio).to eq(1.6855)
    end

    it 'falls back to 16:9 without a player width' do
      cmi5_item.update!(player_width: nil, player_height: 1151)

      expect(cmi5_item.player_aspect_ratio).to eq(16.0 / 9)
    end

    it 'falls back to 16:9 without a player height' do
      cmi5_item.update!(player_width: 1940, player_height: nil)

      expect(cmi5_item.player_aspect_ratio).to eq(16.0 / 9)
    end

    it 'falls back to 16:9 with a zero player height' do
      cmi5_item.update!(player_width: 1940, player_height: 0)

      expect(cmi5_item.player_aspect_ratio).to eq(16.0 / 9)
    end
  end
end
