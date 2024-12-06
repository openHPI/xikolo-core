# frozen_string_literal: true

require 'spec_helper'

describe ReviewDecorator, type: :decorator do
  let(:review) { build(:review) }
  let(:review_decorator) { ReviewDecorator.new review }

  context 'as_api_v1' do
    subject { json }

    let(:json) { review_decorator.as_json(api_version: 1).stringify_keys }

    it { is_expected.to include('id') }
    it { is_expected.to include('user_id') }
    it { is_expected.to include('step_id') }
    it { is_expected.to include('submission_id') }
    it { is_expected.to include('text') }
    it { is_expected.to include('submitted') }
    it { is_expected.to include('award') }
    it { is_expected.to include('feedback_grade') }
    it { is_expected.to include('train_review') }
    it { is_expected.to include('optionIDs') }
    it { is_expected.to include('deadline') }
    it { is_expected.to include('grade') }
    it { is_expected.to include('suspended') }
    it { is_expected.to include('extended') }
  end
end
