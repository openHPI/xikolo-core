# frozen_string_literal: true

require 'spec_helper'

describe Pinboard::Topic, type: :component do
  subject(:component) { described_class.new(topic, course_code) }

  let(:topic) { build(:'pinboard:question', title: 'Coding Example', updated_at: 1.day.ago) }
  let(:course_code) { 'course-123' }
  let!(:section) { build(:'course:section', title: 'Week 1') }

  describe '#css_classes' do
    context 'when the topic is pinned' do
      let(:topic) { super().merge('sticky' => true) }

      it 'adds specific sticky class' do
        render_inline component

        expect(component.css_classes).to eq 'pinboard-question sticky unread'
      end
    end
  end

  describe '#title' do
    context 'when the topic is blocked' do
      let(:topic) { super().merge('abuse_report_state' => 'blocked') }

      it 'adds a blocked prefix to the title' do
        render_inline(component)

        expect(component.title).to eq '[Blocked] Coding Example'
      end
    end
  end

  describe '#url' do
    it 'returns the URL of the topic' do
      render_inline(component)

      expect(component.url).to eq "/courses/course-123/question/#{topic['id']}"
    end

    context 'when it belongs to the pinboard of a section' do
      let(:topic) { super().merge('section_id' => section['id']) }

      it 'returns the URL of the topic in the context of the section' do
        render_inline(component)

        expect(component.url).to eq "/courses/course-123/question/#{topic['id']}?section_id=#{section['id']}"
      end
    end
  end

  describe '#tags' do
    let(:topic) { super().merge('implicit_tags' => implicit_tags, 'user_tags' => user_tags) }

    let(:implicit_tags) do
      [
        {'name' => section['id'], 'referenced_resource' => 'Xikolo::Course::Section', 'id' => '81e01000-0000-4444-a000-000000000004'},
      ]
    end
    let(:user_tags) do
      [
        {'name' => 'Coding', 'id' => '81e01000-0000-4444-a000-000000000003'},
      ]
    end

    before do
      Stub.service(:course, build(:'course:root'))
      Stub.request(:course, :get,
        "/sections/#{section['id']}").to_return Stub.json(section)
    end

    it 'returns both user and implicit tags' do
      render_inline(component)

      expect(component.tags).to contain_exactly(
        {name: 'Coding', id: '81e01000-0000-4444-a000-000000000003'},
        {name: 'Week 1', id: '81e01000-0000-4444-a000-000000000004'}
      )
    end
  end
end
