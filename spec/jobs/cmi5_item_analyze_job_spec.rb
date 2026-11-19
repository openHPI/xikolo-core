# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cmi5ItemAnalyzeJob, type: :job do
  let(:cmi5_item) { create(:cmi5_item) }

  before { Cmi5ItemUnzipJob.perform_now(cmi5_item) }

  it 'stores the player dimensions' do
    described_class.perform_now(cmi5_item)
    cmi5_item.reload

    expect(cmi5_item.player_width).to eq(1940)
    expect(cmi5_item.player_height).to eq(1151)
  end
end
