# frozen_string_literal: true

require 'spec_helper'

describe 'Items: Destroy', type: :request do
  subject(:request) { api.rel(:item).delete({id: item.id}).value! }

  let(:item) { create(:'course_service/item') }
  let(:api) { Restify.new(:test).get.value }

  before do
    item
    create_list(:'course_service/visit', 3, item:)
    create(:'course_service/visit')
    create_list(:'course_service/result', 4, item:)
    create(:'course_service/result')
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
