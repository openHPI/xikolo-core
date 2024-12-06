# frozen_string_literal: true

require 'spec_helper'

describe 'Grades: Index', type: :request do
  subject(:index) do
    test_api.rel(:grades).get(params).value!
  end

  let(:test_api) { Restify.new(:test).get.value! }
  let!(:submission) { create(:submission) } # Creates a grade in hook
  let(:params) { {submission_id: submission.id} }

  # rubocop:disable RSpec/AnyInstance
  before do
    allow_any_instance_of(Grade).to receive(:compute_grade).and_return 10.0
    allow_any_instance_of(Grade).to receive(:regradable?).and_return true
  end
  # rubocop:enable all

  context 'with a valid grade' do
    it { is_expected.to respond_with :ok }

    it 'contains the expected grades' do
      expect(index.size).to eq 1
      expect(index.first).to include(
        'id',
        'submission_id',
        'overall_grade',
        'base_points',
        'bonus_points',
        'delta',
        'absolute',
        'regradable'
      )
    end
  end

  context 'with non-existing grade' do
    let(:params) { {submission_id: SecureRandom.uuid} }

    it { is_expected.to match_array [] }
  end
end
