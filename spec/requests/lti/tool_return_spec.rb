# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'LTI: ToolReturn', type: :request do
  subject(:show_item) do
    get "/courses/#{course.course_code}/items/#{item['id']}/tool_return", headers:, params: query
  end

  let(:user_id) { generate(:user_id) }
  let(:course) { create(:course, context_id: SecureRandom.uuid) }
  let(:course_resource) do
    build(:'course:course', id: course.id, course_code: course.course_code, context_id: course.context_id)
  end
  let(:section) { build(:'course:section', course_id: course.id) }
  let(:item) do
    build(:'course:item', section_id: section['id'], content_type: 'lti', title: 'The LTI Item', open_mode: false, published: true)
  end
  let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:query) { {} }

  before do
    Stub.request(:course, :get, "/courses/#{course.course_code}")
      .to_return Stub.json(course_resource)
    Stub.request(
      :course, :get, "/items/#{item['id']}",
      query: {user_id:}
    ).to_return Stub.json(item)
    Stub.request(
      :course, :get, '/enrollments',
      query: {user_id:, course_id: course.id}
    ).to_return Stub.json([{course_id: course.id, user_id:}])

    stub_user_request id: user_id, context_id: course.context_id
  end

  context 'with LTI tool message' do
    let(:query) { {lti_msg: "<img%20src=x%20onerror=alert('hello, message')>"} }

    it 'prevents XSS by escaping the tool message' do
      show_item

      expect(flash[:notice].first).to eq '&lt;img%20src=x%20onerror=alert(&#39;hello, message&#39;)&gt;'
    end
  end

  context 'with LTI tool error message' do
    let(:query) { {lti_errormsg: "<img%20src=x%20onerror=alert('hello, error')>"} }

    it 'prevents XSS by escaping the error message' do
      show_item

      expect(flash[:error].first).to eq '&lt;img%20src=x%20onerror=alert(&#39;hello, error&#39;)&gt;'
    end
  end
end
