# frozen_string_literal: true

require 'spec_helper'

describe PinboardService::ImplicitTag, type: :model do
  let(:tag) { create(:'pinboard_service/implicit_tag') }

  it 'sets the correct type' do
    expect(tag.type).to eq('PinboardService::ImplicitTag')
  end
end
