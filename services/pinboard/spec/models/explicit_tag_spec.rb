# frozen_string_literal: true

require 'spec_helper'

describe ExplicitTag, type: :model do
  let!(:tag) { create(:'pinboard_service/explicit_tag') }

  it 'sets the correct type' do
    expect(tag.type).to eq('ExplicitTag')
  end

  it 'loads only explicit tags' do
    expect(ExplicitTag.count).to eq(1)
    create(:'pinboard_service/implicit_tag')
    expect(ExplicitTag.count).to eq(1)
  end
end
