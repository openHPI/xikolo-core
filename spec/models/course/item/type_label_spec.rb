# frozen_string_literal: true

require 'spec_helper'

describe Course::Item::TypeLabel do
  subject(:label) { described_class.from_resource(item).text }

  let(:item) { {'content_type' => content_type, 'exercise_type' => exercise_type} }
  let(:exercise_type) { nil }

  {
    'Video::Video' => 'Video',
    'CourseService::Richtext' => 'Text',
    'Lti::Exercise' => 'Learning materials',
    'peer_assessment' => 'Learning materials',
  }.each do |type, text|
    context "for a #{type} item" do
      let(:content_type) { type }

      it { is_expected.to eq text }
    end
  end

  context 'for a quiz' do
    let(:content_type) { 'QuizService::Quiz' }

    {
      'selftest' => 'Self-test',
      'main' => 'Graded Test',
      'bonus' => 'Bonus Test',
      'exam' => 'Exam',
      'survey' => 'Survey',
      nil => 'Self-test',
    }.each do |type, text|
      context "with exercise type #{type.inspect}" do
        let(:exercise_type) { type }

        it { is_expected.to eq text }
      end
    end
  end

  context 'for an item model' do
    let(:item) { build(:'course_service/item', :quiz, exercise_type: 'exam') }

    it { is_expected.to eq 'Exam' }
  end
end
