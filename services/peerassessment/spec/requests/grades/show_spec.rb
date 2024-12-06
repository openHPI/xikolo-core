# frozen_string_literal: true

require 'spec_helper'

describe 'Grades: Show', type: :request do
  subject(:show) do
    test_api.rel(:grade).get(params).value!
  end

  let(:test_api) { Restify.new(:test).get.value! }
  let!(:submission) { create(:submission) } # Creates a grade in hook
  let!(:grade) { submission.grade }
  let(:params) { {id: grade.id} }

  # rubocop:disable RSpec/AnyInstance
  before do
    allow_any_instance_of(Grade).to receive(:compute_grade).and_return 10.0
    allow_any_instance_of(Grade).to receive(:regradable?).and_return true
  end
  # rubocop:enable all

  context 'with a valid grade' do
    it { is_expected.to respond_with :ok }

    it { is_expected.to include('id', 'overall_grade', 'regradable') }
  end

  context 'with non-existing grade' do
    let(:params) { {id: SecureRandom.uuid} }

    it 'returns with 404 not found' do
      expect { show }.to raise_error Restify::NotFound
    end
  end
end
