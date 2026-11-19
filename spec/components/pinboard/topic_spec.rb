# frozen_string_literal: true

require 'spec_helper'

describe Pinboard::Topic, type: :component do
  subject(:component) { described_class.new(topic, course_code) }

  let(:topic) { create(:'pinboard_service/question', title: 'Coding Example', updated_at: 1.day.ago) }
  let(:course_code) { 'course-123' }

  describe '#css_classes' do
    context 'when the topic is pinned' do
      let(:topic) { create(:'pinboard_service/question', title: 'Coding Example', sticky: true, updated_at: 1.day.ago) }

      it 'adds specific sticky class' do
        render_inline component

        expect(component.css_classes).to eq 'pinboard-question sticky unread'
      end
    end
  end

  describe '#title' do
    context 'when the topic is blocked' do
      let(:topic) { create(:'pinboard_service/question', title: 'Coding Example', workflow_state: 'blocked', updated_at: 1.day.ago) }

      it 'adds a blocked prefix to the title' do
        render_inline(component)

        expect(component.title).to eq '[Blocked] Coding Example'
      end
    end
  end

  describe '#url' do
    it 'returns the URL of the topic' do
      render_inline(component)

      expect(component.url).to eq "/learn/course-123/question/#{topic.id}"
    end
  end

  describe '#tags' do
    let(:section) { create(:'course_service/section', title: 'Week 1') }
    let(:implicit_tag) do
      PinboardService::ImplicitTag.create!(
        name: section.id,
        referenced_resource: 'Xikolo::Course::Section',
        course_id: topic.course_id
      )
    end
    let(:explicit_tag) do
      PinboardService::ExplicitTag.create!(
        name: 'Coding',
        course_id: topic.course_id
      )
    end

    before do
      topic.tags << implicit_tag << explicit_tag
      topic.reload
    end

    it 'returns both user and implicit tags' do
      render_inline(component)

      expect(component.tags).to contain_exactly(
        {name: 'Coding', id: explicit_tag.id},
        {name: 'Week 1', id: implicit_tag.id}
      )
    end
  end
end
