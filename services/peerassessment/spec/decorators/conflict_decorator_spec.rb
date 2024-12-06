# frozen_string_literal: true

require 'spec_helper'

describe ConflictDecorator, type: :decorator do
  let(:conflict_decorator) { described_class.new build(:conflict) }

  context 'as_api_v1' do
    subject(:json) { conflict_decorator.as_json(api_version: 1).stringify_keys }

    it 'contains the expected attributes' do
      expect(json).to include(
        'id',
        'reporter',
        'conflict_subject_id',
        'conflict_subject_type',
        'open',
        'comment'
      )
    end
  end
end
