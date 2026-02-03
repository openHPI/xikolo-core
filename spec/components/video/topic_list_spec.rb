# frozen_string_literal: true

require 'spec_helper'

describe Video::TopicList, type: :component do
  subject(:component) { described_class.new item:, user: }

  let(:item) do
    instance_double(ItemPresenter,
      id: generate(:item_id),
      course_code: 'the_course',
      course_pinboard_closed?: false)
  end
  let(:user) { Xikolo::Common::Auth::CurrentUser.from_session(user_session) }
  let(:user_session) do
    {
      'permissions' => [],
      'features' => {},
      'user' => {'anonymous' => false},
      'user_id' => generate(:user_id),
    }
  end

  context 'with no topics available' do
    before do
      Stub.request(
        :pinboard, :get, '/topics',
        query: {item_id: item.id}
      ).to_return Stub.json([])
    end

    it 'does not show any topic and displays the empty state' do
      render_inline(component)

      expect(page).to have_no_selector '[data-slider-target="item"]'
      expect(page).to have_content 'There are no discussion topics yet'
    end

    context 'with course pinboard closed' do
      let(:item) do
        instance_double(ItemPresenter,
          id: generate(:item_id),
          course_code: 'the_course',
          course_pinboard_closed?: true)
      end

      it 'only shows a callout' do
        render_inline(component)

        expect(page).to have_no_selector '[data-slider-target="item"]'
        expect(page).to have_no_content 'There are no discussion topics yet'
        expect(page).to have_content 'The discussions for this course are read-only.'
      end
    end
  end

  context 'with topics available' do
    let(:current) { Time.current }
    let(:topic1) do
      {id: SecureRandom.uuid, title: 'Topic 1', created_at: current - 2.hours, meta: {video_timestamp: 20}, tags: []}
    end
    let(:topic2) do
      {id: SecureRandom.uuid, title: 'Topic 2', created_at: current - 1.hour, meta: {video_timestamp: 20}, tags: []}
    end
    let(:topic3) do
      {id: SecureRandom.uuid, title: 'Topic 3', created_at: current - 10.minutes, meta: {video_timestamp: 10}, tags: []}
    end
    let(:topic4) do
      {id: SecureRandom.uuid, title: 'Topic 4', created_at: current - 10.minutes, meta: {video_timestamp: 0}, tags: []}
    end

    before do
      Stub.request(
        :pinboard, :get, '/topics',
        query: {item_id: item.id}
      ).to_return Stub.json([topic1, topic2, topic3, topic4])
    end

    it 'lists the topics' do
      render_inline(component)

      expect(page).to have_content 'Discussion topics'
      expect(page).to have_content '4 topics'
      expect(page).to have_content 'Topic', count: 4
      expect(page).to have_link 'View or reply'
    end

    it 'orders the topics by video timestamp and creation date' do
      render_inline(component)
      container = page.find '[data-slider-target="content"]'

      expect(container.text).to match(/Topic 4.+Topic 3.+Topic 1.+Topic 2/)
    end

    it 'allows to create new topics' do
      render_inline(component)

      expect(page).to have_button 'Start a new topic'
    end

    context 'for anonymous user' do
      let(:user_session) do
        {
          'permissions' => [],
          'features' => {},
          'user' => {'anonymous' => true},
        }
      end

      it 'hides the component' do
        render_inline(component)

        expect(page).to have_content ''
      end
    end

    context 'with course pinboard closed' do
      let(:item) do
        instance_double(ItemPresenter,
          id: generate(:item_id),
          course_code: 'the_course',
          course_pinboard_closed?: true)
      end

      it 'lists the topics' do
        render_inline(component)

        expect(page).to have_content 'Discussion topics'
        expect(page).to have_content '4 topics'
        expect(page).to have_content 'Topic', count: 4
        expect(page).to have_link 'Read more'
      end

      it 'does not allow to create new topics' do
        render_inline(component)

        expect(page).to have_content 'The discussions for this course are read-only.'
        expect(page).to have_no_button 'Start a new topic'
      end
    end
  end

  context 'with pinboard response error' do
    before do
      Stub.request(
        :pinboard, :get, '/topics',
        query: {item_id: item.id}
      ).to_return Stub.response(status: 500)
    end

    it 'hides the component' do
      render_inline(component)

      expect(page).to have_content ''
    end
  end
end
