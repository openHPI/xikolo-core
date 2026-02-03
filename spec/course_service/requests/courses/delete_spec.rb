# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Delete', type: :request do
  subject(:action) { api.rel(:course).delete({id: course.id}).value! }

  let(:api) { restify_with_headers(course_service.root_url).get.value! }
  let(:orig_course_code) { 'the-course-code' }
  let(:course) { create(:'course_service/course', course_code: orig_course_code) }

  %w[students admins moderators teachers].each do |name|
    let!(:"group_#{name}_stub") do
      Stub.request(
        :account,
        :delete,
        "/groups/course.#{course.course_code}.#{name}"
      ).to_return(status: 200)
    end
  end

  before do
    Stub.request(
      :account,
      :delete,
      "/contexts/#{course.context_id}"
    ).to_return(status: 200)
  end

  it 'responds with 204 No Content' do
    expect(action.response.status).to eq :no_content
  end

  context 'with failing account service' do
    let(:group_admins_stub) do
      Stub.request(
        :account,
        :delete,
        "/groups/course.#{course.course_code}.admins"
      ).to_return(status: 500)
    end

    it 'responds with 204 No Content' do
      expect(action.response.status).to eq :no_content
    end
  end
end
