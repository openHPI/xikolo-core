# frozen_string_literal: true

require 'spec_helper'

describe Answer, type: :model do
  it 'has a valid factory' do
    expect(create(:'pinboard_service/answer')).to be_valid
  end

  describe 'blocked?' do
    it_behaves_like 'a reportable', :'pinboard_service/answer'
  end

  describe 'resetting the reviewed flag' do
    it_behaves_like 'a reviewed reportable', :'pinboard_service/question', :text
  end

  context '(event publication)' do
    subject(:answer) { build(:'pinboard_service/answer', attachment_uri: 's3://xikolo-pinboard/courses/34/thread/12/3/file.pdf') }

    it 'publishes an event for newly created answer' do
      allow(Msgr).to receive(:publish)
      expect(Msgr).to receive(:publish).with(anything, hash_including(to: 'xikolo.pinboard.answer.create')) do |event, _opts|
        expect(event).to eq \
          id: answer.id,
          text: answer.text,
          question_id: answer.question_id,
          created_at: answer.created_at.iso8601,
          updated_at: answer.updated_at.iso8601,
          user_id: answer.user_id,
          votes: answer.votes_sum,
          attachment_url: 'https://s3.xikolo.de/xikolo-pinboard/courses/34/thread/12/3/file.pdf',
          unhelpful_answer_score: answer.unhelpful_answer_score,
          ranking: answer.ranking,
          course_id: answer.question.course_id,
          technical: false,
          abuse_report_state: 'new',
          abuse_report_count: 0
      end
      answer.save
    end

    it 'pubishes an event for updated answer' do
      answer.save

      allow(Msgr).to receive(:publish) # question update
      expect(Msgr).to receive(:publish).with(anything, hash_including(to: 'xikolo.pinboard.answer.update')) do |updated_answer_as_hash, _msgr_params|
        expect(updated_answer_as_hash).to be_a(Hash)
        expect(updated_answer_as_hash).to include('text' => 'Foo is the correct answer')
      end

      answer.text = 'Foo is the correct answer'
      answer.save
    end
  end

  context 'sum up votes' do
    subject(:answer) { create(:'pinboard_service/answer') }

    before { create(:'pinboard_service/vote', votable_id: answer.id, votable_type: answer.class.name, value: 1, user_id: '00000001-3100-4444-9999-000000000001') }

    it 'calculates positive votes correctly' do
      create(:'pinboard_service/vote', votable_id: answer.id, votable_type: answer.class.name, value: 1, user_id: '00000001-3100-4444-9999-000000000002')
      expect(answer.votes_sum).to eq(2)
    end

    it 'calculates negative votes correctly' do
      create(:'pinboard_service/vote', votable_id: answer.id, votable_type: answer.class.name, value: -1, user_id: '00000001-3100-4444-9999-000000000002')
      create(:'pinboard_service/vote', votable_id: answer.id, votable_type: answer.class.name, value: -1, user_id: '00000001-3100-4444-9999-000000000003')
      expect(answer.votes_sum).to eq(-1)
    end
  end

  describe 'sorting' do
    let!(:answer1) { create(:'pinboard_service/answer') }
    let!(:answer2) { create(:'pinboard_service/answer') }
    let!(:answer3) { create(:'pinboard_service/answer') }
    let!(:answer4) { create(:'pinboard_service/answer') }

    context 'by sum of votes, same votes chronologically' do
      before do
        create(:'pinboard_service/vote', votable_id: answer1.id,
          votable_type: answer1.class.name,
          value: 1,
          user_id: '00000001-3100-4444-9999-000000000001')
        create(:'pinboard_service/vote', votable_id: answer2.id,
          votable_type: answer1.class.name,
          value: -1,
          user_id: '00000001-3100-4444-9999-000000000001')
      end

      context 'votes descending, chronologically' do
        subject { Answer.order_by_votes(:desc).pluck :id }

        let(:right_order) { [answer1.id, answer3.id, answer4.id, answer2.id] }

        it { is_expected.to eq right_order }

        it { is_expected.to match(right_order) }
      end

      context 'ascending' do
        subject { Answer.order_by_votes(:asc).pluck :id }

        let(:right_order) { [answer2.id, answer3.id, answer4.id, answer1.id] }

        it { is_expected.to eq right_order }

        it { is_expected.to match(right_order) }
      end
    end
  end

  describe 'answering a discussion' do
    subject { build(:'pinboard_service/answer', question:) }

    let(:question) { create(:'pinboard_service/question', discussion_flag: true) }

    it { is_expected.to be_valid }
  end

  describe 'question_title' do
    subject(:answer) { create(:'pinboard_service/answer', question:) }

    let(:question) { create(:'pinboard_service/question') }

    it 'calls #title on the question' do
      answer
      expect(question).to receive(:title)
      answer.question_title
    end
  end

  describe 'soft-deletion' do
    subject(:soft_deletion) { answer.soft_delete }

    let(:answer) { create(:'pinboard_service/answer') }

    it 'decreases the public answer count' do
      expect do
        soft_deletion
      end.to change { answer.question.public_answers_count }.by(-1)
    end
  end

  describe 'destroying' do
    subject(:deletion) { answer.destroy }

    let(:answer) { create(:'pinboard_service/answer') }

    it 'decreases the public answer count' do
      expect do
        deletion
      end.to change { answer.question.public_answers_count }.by(-1)
    end
  end

  describe 'blocking' do
    subject(:blocking) { answer.block! }

    let(:answer) { create(:'pinboard_service/answer') }

    it 'decreases the public answer count' do
      expect do
        blocking
      end.to change { answer.question.public_answers_count }.by(-1)
    end
  end

  describe 'auto-blocking' do
    subject(:auto_blocking) { answer.update!(workflow_state: :auto_blocked) }

    let(:answer) { create(:'pinboard_service/answer') }

    it 'decreases the public answer count' do
      expect do
        auto_blocking
      end.to change { answer.question.public_answers_count }.by(-1)
    end
  end
end
