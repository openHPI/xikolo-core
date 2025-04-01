# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User Tests: Create', type: :request do
  subject(:post_request) { api.rel(:user_tests).post(payload).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:payload) do
    attributes_for(:user_test, identifier: 'user_test').merge(test_groups: [
      {name: 'Control', description: 'The control group', flippers: []},
      {name: 'Alternative', description: 'These should make more posts', flippers: ['new_pinboard']},
    ])
  end

  let!(:group_post_stubs) do
    (0..1).map do |i|
      Stub.request(
        :account, :post, '/groups',
        body: {name: "grouping.user_test.#{i}"}
      )
    end
  end

  let!(:flippers_post_stubs) do
    [
      Stub.request(
        :account, :patch, '/groups/grouping.user_test.0/flippers',
        query: {context: 'root'},
        body: {}
      ),
      Stub.request(
        :account, :patch, '/groups/grouping.user_test.1/flippers',
        query: {context: 'root'},
        body: {'new_pinboard' => true}
      ),
    ]
  end

  before do
    (0..1).map do |i|
      Stub.request(
        :account, :get, "/groups/grouping.user_test.#{i}"
      ).to_return Stub.json({
        flippers_url: "/groups/grouping.user_test.#{i}/flippers",
      })
    end
  end

  it 'creates a new user test' do
    expect { post_request }.to change(UserTest, :count).from(0).to(1)
  end

  it 'responds with a representation of the newly created test' do
    expect(post_request['id']).to eq UserTest.first.id
  end

  it 'creates the provided test groups' do
    expect { post_request }.to change(TestGroup, :count).by(2)

    control = TestGroup.find_by(index: 0)
    alt = TestGroup.find_by(index: 1)

    expect(control).to have_attributes(
      name: 'Control',
      description: 'The control group',
      flippers: []
    )
    expect(alt).to have_attributes(
      name: 'Alternative',
      description: 'These should make more posts',
      flippers: ['new_pinboard']
    )
  end

  it 'creates groups in the account service' do
    post_request

    expect(group_post_stubs).to all have_been_requested
  end

  it 'creates flippers in the account service' do
    post_request

    expect(flippers_post_stubs).to all have_been_requested
  end

  context 'with metrics' do
    let(:payload) { super().merge(metrics: metrics_attributes) }
    let(:metrics_attributes) do
      [
        {'type' => 'CoursePoints', 'wait_interval' => 0},
        {'type' => 'CourseActivity', 'wait_interval' => 60},
      ]
    end

    it 'uses the supplied metrics for the user test' do
      post_request

      expect(UserTest.first.metrics).to match contain_exactly(
        have_attributes(type: 'CoursePoints', wait_interval: 0),
        have_attributes(type: 'CourseActivity', wait_interval: 60)
      )
    end
  end

  context 'with filters' do
    let(:payload) { super().merge(filter_strings: ['enrollments < 2', 'gender == female']) }

    it 'creates the correct number of filters' do
      expect { post_request }.to change(Filter, :count).by(2)
    end

    it 'creates filters' do
      post_request

      expect(UserTest.first.filters).to match contain_exactly(
        have_attributes(field_name: 'enrollments', operator: '<', field_value: '2'),
        have_attributes(field_name: 'gender', operator: '==', field_value: 'female')
      )
    end
  end

  context 'with invalid payload' do
    let(:payload) { {name: nil} }

    it 'responds with 400 Bad Request' do
      expect { post_request }.to raise_error(Restify::BadRequest)
    end
  end
end
