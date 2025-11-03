# frozen_string_literal: true

require 'spec_helper'

describe Watch, type: :model do
  subject(:watch) { create(:'pinboard_service/watch', attributes) }

  let(:attributes) { {} }

  it { is_expected.to be_valid }

  describe 'uniqueness of question and user' do
    subject(:other_watch) { build(:'pinboard_service/watch', other_attributes) }

    let(:other_attributes) { {} }

    context 'with same user_id' do
      let(:other_attributes) { {user_id: watch.user_id} }

      it { is_expected.to be_valid }
    end

    context 'with same question_id' do
      let(:other_attributes) { {question_id: watch.question_id, user_id: '00000001-3100-4444-9999-000000000002'} }

      it { is_expected.to be_valid }
    end

    context 'with same user_id and question_id' do
      let(:other_attributes) { {user_id: watch.user_id, question_id: watch.question_id} }

      it { is_expected.not_to be_valid }
    end
  end

  describe 'create' do
    subject(:watch) { build(:'pinboard_service/watch', attributes) }

    it 'publishes an event for newly created watch' do
      attrs = {
        question_id: watch.question_id,
        user_id: watch.user_id,
        course_id: watch.course_id,
      }
      expect(Msgr).to receive(:publish)
        .with(hash_including(attrs),
          to: 'xikolo.pinboard.watch.create')
      watch.save
    end
  end
end
