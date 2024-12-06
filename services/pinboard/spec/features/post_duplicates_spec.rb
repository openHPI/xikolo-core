# frozen_string_literal: true

require 'spec_helper'

describe 'Posting duplicate questions', type: :request do
  let(:params) do
    {
      user_id: SecureRandom.uuid,
      title: 'Foo',
      text: 'bar',
    }
  end

  let(:action) { ->(params) { create(:question, params) } }

  context 'across multiple courses' do
    it 'allows identical questions' do
      5.times do
        action.call params.merge!(course_id: SecureRandom.uuid)
      end
      expect(Question.count).to eq 5
    end
  end

  context 'within one course' do
    let(:params) { super().merge!(course_id: SecureRandom.uuid) }

    it 'does not allow identical questions within one courses' do
      action.call params
      expect { action.call params }.to raise_error ActiveRecord::RecordNotUnique
    end
  end
end
