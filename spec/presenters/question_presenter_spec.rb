# frozen_string_literal: true

require 'spec_helper'

describe QuestionPresenter, type: :presenter do
  let(:presenter) { described_class.build question, course, section_id }
  let(:question) { Xikolo::Pinboard::Question.new params }
  let(:params) do
    {
      id: SecureRandom.uuid,
      user_id: SecureRandom.uuid,
      title:,
      implicit_tags: [],
    }
  end
  let(:title) { 'test' }
  let(:course) { Xikolo::Course::Course.new id: SecureRandom.uuid, course_code: 'test' }
  let(:section_id) { SecureRandom.uuid }
  let(:answer_id) { SecureRandom.uuid }

  before do
    Stub.service(:pinboard, build(:'pinboard:root'))

    Stub.request(
      :pinboard, :get, '/explicit_tags',
      query: {question_id: question.id}
    ).to_return Stub.json([])

    Stub.request(
      :account, :get, "/users/#{question.user_id}"
    ).to_return Stub.json({name: 'Test User'})

    Stub.request(
      :pinboard, :get, '/answers',
      query: {question_id: question.id, per_page: '250'}
    ).to_return Stub.json([
      {id: answer_id},
    ])

    Stub.request(
      :pinboard, :get, '/comments',
      query: {commentable_id: question.id, commentable_type: 'Question', per_page: '250'}
    ).to_return Stub.json([])

    Stub.request(
      :pinboard, :get, '/comments',
      query: {commentable_id: answer_id, commentable_type: 'Answer', per_page: '250'}
    ).to_return Stub.json([])

    presenter
    Acfs.run
  end

  describe 'title' do
    subject { presenter.title }

    context 'by default' do
      it { is_expected.to eq title }
    end

    context 'with blocked question' do
      let(:params) { super().merge abuse_report_state: 'blocked' }

      it { is_expected.to eq "[Blocked] #{title}" }
    end
  end

  describe 'read?' do
    subject { presenter.read? }

    context 'by default' do
      it { is_expected.to be_falsy }
    end

    context 'with read state on question' do
      let(:params) { super().merge read: true }

      it { is_expected.to be_truthy }
    end
  end

  describe 'answer_count' do
    subject { presenter.answer_count }

    it { is_expected.to eq 1 }
  end

  describe 'comment_count' do
    subject { presenter.comment_count }

    it { is_expected.to eq 0 }
  end

  describe 'answer_comment_count' do
    subject { presenter.answer_comment_count }

    it { is_expected.to eq 0 }
  end
end
