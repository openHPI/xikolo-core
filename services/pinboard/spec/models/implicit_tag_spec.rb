# frozen_string_literal: true

require 'spec_helper'

describe ImplicitTag, type: :model do
  let(:tag) { create(:implicit_tag) }

  it 'sets the correct type' do
    expect(tag.type).to eq('ImplicitTag')
  end
end
