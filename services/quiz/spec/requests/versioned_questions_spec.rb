# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Versioned Questions', :versioning, type: :request do
  let(:api) { Restify.new(:test).get.value! }

  let(:question) { create(:multiple_choice_question, points: 3) }

  before do
    Stub.service(
      :course,
      items_url: 'http://course.xikolo.tld/items',
      item_url: 'http://course.xikolo.tld/items/{id}'
    )
    Stub.request(
      :course, :get, '/items',
      query: {content_id: question.quiz_id}
    ).to_return Stub.json([
      {id: '53d99410-28c1-4516-8ef5-49ed0e593918', max_points: 10.0},
    ])
    Stub.request(
      :course, :patch, '/items/53d99410-28c1-4516-8ef5-49ed0e593918',
      body: hash_including(max_points: 9.0)
    ).to_return Stub.json({max_points: 9.0})
    Stub.request(
      :course, :patch, '/items/53d99410-28c1-4516-8ef5-49ed0e593918',
      body: hash_including(max_points: 6.0)
    ).to_return Stub.json({max_points: 6.0})
    Stub.request(
      :course, :patch, '/items/53d99410-28c1-4516-8ef5-49ed0e593918',
      body: hash_including(max_points: 4.0)
    ).to_return Stub.json({max_points: 4.0})
    Stub.request(
      :course, :patch, '/items/53d99410-28c1-4516-8ef5-49ed0e593918',
      body: hash_including(max_points: 3.0)
    ).to_return Stub.json({max_points: 3.0})
    Stub.request(
      :course, :patch, '/items/53d99410-28c1-4516-8ef5-49ed0e593918',
      body: hash_including(max_points: 2.0)
    ).to_return Stub.json({max_points: 2.0})
  end

  it 'returns one version at the beginning' do
    expect(question.versions.size).to be 1
  end

  it 'returns two versions when modified' do
    api.rel(:question).put({points: 4}, {id: question.id}).value!
    question.reload
    expect(question.versions.size).to be 2
  end

  it 'answers with the previous version' do
    api.rel(:question).put({points: 4}, {id: question.id}).value!
    question.reload
    expect(question.points).to eq 4
    expect(question.paper_trail.previous_version.points).to eq 3
  end

  context 'with given timestamp' do
    # TODO: Move resources in let/before blocks
    it 'returns version of question at this time' do
      Timecop.travel(2008, 9, 1, 12, 0, 0)
      question
      Timecop.travel(2010, 9, 1, 12, 0, 0)
      api.rel(:question).put({points: 4}, {id: question.id}).value!
      Timecop.return

      question.reload
      expect(question.points).to eq 4

      json = api.rel(:question).get(
        id: question.id,
        version_at: DateTime.new(2009, 9, 1, 12, 0, 0).to_s
      ).value!

      expect(json['points']).to eq 3
    end

    it 'returns list with questions in version at this time' do
      Timecop.travel(2008, 9, 1, 12, 0, 0)
      question1 = question
      question2 = create(:multiple_choice_question, quiz: question1.quiz, points: 2)
      Timecop.travel(2010, 9, 1, 12, 0, 0)
      api.rel(:question).put({points: 4}, {id: question1.id}).value!
      api.rel(:question).put({points: 5}, {id: question2.id}).value!
      Timecop.return

      question1.reload
      question2.reload
      expect(question1.points).to eq 4
      expect(question2.points).to eq 5

      json = api.rel(:questions).get(
        version_at: DateTime.new(2009, 9, 1, 12, 0, 0).to_s
      ).value!

      expect(json.pluck('points')).to contain_exactly(3, 2)
    end
  end
end
