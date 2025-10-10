# frozen_string_literal: true

require 'spec_helper'

describe SectionsController, type: :controller do
  let!(:section_id) { SecureRandom.uuid }
  let!(:course_id) { SecureRandom.uuid }
  let(:request_context_id) { course_context_id }
  let(:permissions) { [] }

  before do
    Stub.service(:account, build(:'account:root'))
    stub_user id: '1', display_name: 'John Smith', admin: true, permissions: ['course.content.access', 'course.content.edit']

    Stub.service(:course, build(:'course:root'))
    Stub.request(
      :course, :get, "/sections/#{section_id}"
    ).to_return Stub.json({
      id: section_id,
      position: 1,
      course_id:,
    })
    Stub.request(
      :course, :get, "/courses/#{course_id}"
    ).to_return Stub.json({
      id: course_id,
      title: 'Test Course',
      description: 'A Test Course.',
      status: 'active',
      course_code: 'test',
      start_date: DateTime.new(2013, 7, 12).iso8601,
      end_date: DateTime.new(2013, 8, 19).iso8601,
      abstract: 'Test Course abstract.',
      lang: 'en',
      context_id: course_context_id,
    })
    Stub.request(
      :course, :get, '/enrollments',
      query: {course_id:, user_id: '1'}
    ).to_return Stub.json([])
  end

  describe 'GET #index' do
    subject(:request) { get :index, params: {course_id:} }

    before do
      create(:course, id: course_id)
    end

    it 'answers with a page' do
      expect(request.status).to eq 200
    end
  end

  describe 'POST move' do
    let!(:update) do
      Stub.request(
        :course, :put, "/sections/#{section_id}",
        body: hash_including(course_id:, position: 4)
      ).to_return Stub.json({})
    end

    it 'changes position to 4' do
      post :move, params: {id: section_id, course_id:, position: 4}

      expect(update).to have_been_requested
    end
  end
end
