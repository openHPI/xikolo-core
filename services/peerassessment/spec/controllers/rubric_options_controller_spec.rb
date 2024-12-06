# frozen_string_literal: true

require 'spec_helper'

describe RubricOptionsController, type: :controller do
  let(:json)    { JSON.parse response.body }
  let(:params)  { {format: :json}.merge additional_params }
  let(:additional_params) { {} }
  let!(:rubric) { create(:rubric) }

  describe '#index' do
    subject(:action) { get :index, params: }

    it 'is successful' do
      action
      expect(response).to be_successful
    end

    it 'retrieves all rubric options' do
      action
      expect(json.size).to eq(RubricOption.all.size)
    end

    describe 'for one specific rubric' do
      let(:additional_params) { {rubric_id: rubric.id} }

      it 'retrieves the correct amount of options' do
        action
        expect(json.size).to eq(rubric.rubric_options.size)
      end
    end
  end
end
