# frozen_string_literal: true

require 'spec_helper'

describe FreeTextQuestion, type: :model do
  subject { question }

  let(:question) { create(:free_text_question) }

  describe '#shuffle_answers' do
    subject { super().shuffle_answers }

    it { is_expected.to be false }

    it 'cannot be set to true' do
      expect do
        question.update(shuffle_answers: true)
      end.not_to change { question.reload.shuffle_answers }
    end
  end
end
