# frozen_string_literal: true

require 'spec_helper'

describe PinboardService::Question, '.search', type: :model do
  let(:course_id) { generate(:course_id) }

  let!(:text_match) do
    create(:'pinboard_service/question',
      title: 'A simple question',
      text: 'With a very satisfied text',
      course_id:)
  end

  let!(:title_match) do
    create(:'pinboard_service/question',
      title: 'A satisfied question',
      text: 'With simple and plain text',
      course_id:)
  end

  let!(:answer_match) do
    create(
      :'pinboard_service/question',
      title: 'A not-matching question',
      text: 'With a non-matching text',
      course_id:
    ).tap do |question|
      create(:'pinboard_service/answer',
        question:,
        text: 'With a text that satisfies')
    end
  end

  let!(:comment_match) do
    create(
      :'pinboard_service/question',
      title: 'Another not-matching question',
      text: 'With a non-matching text again',
      course_id:
    ).tap do |question|
      a = create(:'pinboard_service/answer',
        question:,
        text: 'With painful answer')

      create(:'pinboard_service/comment', commentable: a, text: <<~TEXT)
        Lorem ipsum dolor sït amêt, éûm dicit çonsùl mùcius at, usû çù
        êrrêm deniqùe dolœrês, audirè dôlorûm êos ât. Epïcûrei medïoçrem
        in çum. Numqûàm dolores rêctêqùé pro ân, his invénirê maluîssët
        id. Sîmùl singùlis êx vis, nêc cu fâlli accusamùs. Alïa fàcété
        cûm ad. Ex nobis prœmpta habèmûs cûm. Pri môllis tïbiqûe no.
      TEXT
    end
  end

  before do
    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, "/courses/#{course_id}")
      .to_return Stub.json({course_code: 'code2019', lang: 'en'})

    # Ensure above scheduled workers are run to build the search index
    PinboardService::UpdateQuestionSearchTextWorker.drain
  end

  describe '.search' do
    it 'returns results from question title' do
      expect(described_class.search('satisfying', language: 'en')).to include title_match
    end

    it 'returns results from question text' do
      expect(described_class.search('satisfying', language: 'en')).to include text_match
    end

    it 'returns results from answer text match' do
      expect(described_class.search('satisfying', language: 'en')).to include answer_match
    end

    # Test that searching without accents works too (e.g. indexed text is unaccented)
    it 'returns results from answer comments match' do
      expect(described_class.search('dolorum', language: 'en')).to include comment_match
    end
  end
end
