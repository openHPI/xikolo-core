# frozen_string_literal: true

require 'spec_helper'

describe 'Items: Destroy', type: :request do
  subject(:request) { api.rel(:item).delete({id: item.id}).value! }

  let(:item) { create(:item) }
  let(:api) { Restify.new(:test).get.value }

  before do
    item
    create_list(:visit, 3, item:)
    create(:visit)
    create_list(:result, 4, item:)
    create(:result)
  end

  it { is_expected.to respond_with :no_content }

  it 'removes the item from the database' do
    expect { request }.to change(Item, :count).from(3).to(2)
    expect(Item.find_by(id: item.id)).to be_nil
  end

  it 'removes all corresponding visits' do
    expect { request }.to change(Visit, :count).from(4).to(1)
  end

  it 'removes all corresponding results' do
    expect { request }.to change(Result, :count).from(5).to(1)
  end
end
