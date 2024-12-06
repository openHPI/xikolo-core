# frozen_string_literal: true

require 'spec_helper'

describe 'Marking a question sticky', type: :request do
  let(:course_id) { '00000001-3300-4444-9999-000000000001' }

  let!(:question1) { create(:question, course_id:, updated_at: 1.day.ago) }
  let!(:question2) { create(:question, course_id:, updated_at: 2.days.ago) }
  let!(:question3) { create(:question, course_id:, updated_at: 3.days.ago) }
  let!(:question4) { create(:question, course_id:, updated_at: 4.days.ago) }

  let(:old_order) { [question1.id, question2.id, question3.id, question4.id] }
  let(:new_order) { [question3.id, question1.id, question2.id, question4.id] }

  it 'changes the order' do
    questions = Restify.new(:test).get.value!
      .rel(:questions).get(course_id:).value!
    expect(questions.pluck('id')).to eq old_order

    question3.update sticky: true

    questions = Restify.new(:test).get.value!
      .rel(:questions).get(course_id:).value!
    expect(questions.pluck('id')).to eq new_order
  end
end
