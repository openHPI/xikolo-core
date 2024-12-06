# frozen_string_literal: true

require 'spec_helper'

describe ExplicitTag, type: :model do
  let!(:tag) { create(:explicit_tag) }

  it 'sets the correct type' do
    expect(tag.type).to eq('ExplicitTag')
  end

  it 'loads only explicit tags' do
    expect(ExplicitTag.count).to eq(1)
    create(:implicit_tag)
    expect(ExplicitTag.count).to eq(1)
  end
end
