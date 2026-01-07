# frozen_string_literal: true

require 'spec_helper'

describe 'Item User Results: Create', type: :request do
  subject(:creation) do
    api.rel(:item_user_results).post(
      data,
      params: {item_id: item.id, user_id:}
    ).value!
  end

  let(:api) { restify_with_headers(course_service.root_url).get.value! }
  let!(:item) { create(:'course_service/item') }

  let(:data) { {points: 2.3} }
  let(:user_id) { generate(:user_id) }

  it { is_expected.to respond_with :created }

  it 'creates a new result object' do
    expect { creation }.to change(CourseService::Result, :count).from(0).to(1)
  end

  it 'stores dpoints' do
    creation
    result = CourseService::Result.where(item_id: item.id, user_id:).take!
    expect(result.dpoints).to eq 23
  end

  context 'when given 0 points' do
    let(:data) { {points: 0} }

    it { is_expected.to respond_with :created }

    it 'creates the result object with dpoints' do
      creation
      result = CourseService::Result.where(item_id: item.id, user_id:).take!
      expect(result.dpoints).to eq 0
    end
  end

  context 'with previous result for same item and user' do
    before { create(:'course_service/result', item:, user_id:) }

    it 'creates another result object' do
      expect { creation }.to change(CourseService::Result, :count).from(1).to(2)
    end
  end

  context 'with more than one decimal after the comma' do
    let(:data) { {points: 2.13} }

    it 'errors' do
      expect { creation }.to raise_error(Restify::ClientError) do |err|
        expect(err.status).to eq :unprocessable_content
        expect(err.errors).to eq 'points' => %w[invalid_format]
      end
    end
  end
end
