# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'LTI: ToolReturn', type: :request do
  subject(:show_item) do
    get "/learn/#{course.course_code}/items/#{item.id}/tool_return", params: query
  end

  let(:course) { create(:'course_service/course', :active, :with_content_tree) }
  let(:section) { create(:'course_service/section', course:) }
  let(:item) { create(:'course_service/item', :lti_exercise, section:, title: 'The LTI Item', open_mode: false, published: true) }
  let(:query) { {} }

  before do
    sign_in
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
