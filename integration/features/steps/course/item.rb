# frozen_string_literal: true

module Steps
  module CourseItem
    def create_item(attrs = {})
      section = context.fetch :section
      data = {
        title: 'An Example Item',
        start_date: 14.days.ago,
        end_date: 14.days.from_now,
        section_id: section['id'],
        show_in_nav: true,
      }
      data.merge! attrs
      data.compact!

      Server[:course].api.rel(:items).post(data).value!
    end

    def select_item_to_watch
      context.with :item do |item|
        within(:xpath, "//li[@data-id='#{item['id']}']") do
          find('.fa-eye').click
        end
      end
    end

    Given 'a video item was created' do
      context.assign :item, create_item(
        content_type: 'video',
        content_id: '00000003-3600-4444-9999-000000000001',
        title: 'WWW Introduction'
      )
    end

    Given 'a video item with open mode was created' do
      context.assign :open_mode_item, create_item(
        content_type: 'video',
        content_id: '00000003-3100-4444-9999-000000000001',
        title: 'New Video Title in open mode',
        open_mode: true
      )
    end

    Given 'an unpublished video item was created' do
      context.assign :unpublished_item, create_item(
        content_type: 'video',
        content_id: '00000003-3600-4444-9999-000000000003',
        title: 'New unpublished Video Item',
        published: false
      )
    end

    Given 'a quiz item was created' do
      send :'Given a quiz was created'
      context.with :quiz do |quiz|
        context.assign :item, create_item(content_id: quiz['id'],
          content_type: 'quiz',
          exercise_type: 'selftest',
          max_points: quiz['max_points'])
      end
      send :'Given the quiz intro page can be skipped'
    end

    Given 'a quiz item with one question and answers was created' do
      send :'Given a quiz with one question and answers was created'
      context.with :quiz do |quiz|
        context.assign :item, create_item(content_id: quiz['id'],
          content_type: 'quiz',
          exercise_type: 'selftest',
          max_points: quiz['max_points'])
      end
    end

    Given 'a quiz item with questions and answers was created' do
      send :'Given a quiz with questions and answers was created'
      context.with :quiz do |quiz|
        items = (1..20).map do |i|
          create_item(title: "quiz #{i}",
            content_id: quiz['id'],
            content_type: 'quiz',
            exercise_type: 'selftest',
            max_points: quiz['max_points'])
        end
        context.assign :items, items
        context.assign :item, items.first
      end
    end

    Given 'a main quiz item with questions and answers was created' do
      send :'Given a quiz with questions and answers was created'
      context.with :quiz do |quiz|
        context.assign :item, create_item(content_id: quiz['id'],
          content_type: 'quiz',
          exercise_type: 'main',
          max_points: quiz['max_points'])
      end
    end

    Given 'a main quiz item with one question and answers was created' do
      send :'Given a quiz with one question and answers was created'
      context.with :quiz do |quiz|
        context.assign :item, create_item(content_id: quiz['id'],
          content_type: 'quiz',
          exercise_type: 'main',
          max_points: quiz['max_points'])
      end
    end

    Given 'a survey item with questions and answers was created' do
      send :'Given a survey with questions and answers was created'
      context.with :quiz do |quiz|
        context.assign :item, create_item(content_id: quiz['id'],
          title: 'A survey',
          content_type: 'quiz',
          exercise_type: 'survey',
          max_points: quiz['max_points'])
      end
    end

    def set_item_deadline(item, date)
      Server[:course].api.rel(:item).put({submission_deadline: date},
        {id: item.id}).value!
    end

    Given 'the item deadline has passed' do
      context.with :item do |item|
        set_item_deadline item, 2.days.ago
      end
    end

    Given 'the item deadline has not passed' do
      context.with :item do |item|
        set_item_deadline item, 2.days.from_now
      end
    end

    def set_publish_date(item, date)
      Server[:course].api.rel(:item).put({submission_publishing_date: date},
        {id: item.id}).value!
    end

    Given 'the quiz results are not published' do
      context.with :item do |item|
        set_publish_date item, 2.days.from_now
      end
    end

    Given 'the quiz results are published' do
      context.with :item do |item|
        set_publish_date item, 1.day.ago
      end
    end

    Given 'I add an item' do
      click_on 'Add item'
    end

    Given 'several items were created' do
      items = []
      %w[
        00000003-3600-4444-9999-000000000004
        00000003-3600-4444-9999-000000000005
        00000003-3600-4444-9999-000000000006
        00000003-3600-4444-9999-000000000007
        00000003-3600-4444-9999-000000000008
      ].map.with_index(1) do |content_id, i|
        items << create_item(
          content_type: 'video',
          content_id:,
          title: "Video title #{i}"
        )
      end

      context.assign :items, items
      context.assign :item, items.first
    end

    Given 'I worked on some items' do
      context.with :course, :section, :items do |course, _section, items|
        visit "/courses/#{course['course_code']}/items/#{short_uuid items[0]['id']}"
        visit "/courses/#{course['course_code']}/items/#{short_uuid items[1]['id']}"
      end
    end

    Given 'I worked on all items' do
      context.with :course, :section, :items do |course, _section, items|
        items.each do |item|
          visit "/courses/#{course['course_code']}/items/#{short_uuid item['id']}"
        end
      end
    end

    Given 'I am on the video page' do
      send :'Given I am on the course detail page'
      click_on 'Learnings'
      click_on context.fetch(:item)[:title]
    end

    Then 'I should be on the first items page' do
      context.with :course, :items do |_course, items|
        first_item = items.first
        within 'h2' do
          expect(page).to have_content first_item['title']
        end
      end
    end

    Then 'I should be on last visited items page' do
      context.with :course, :items do |_course, items|
        within 'h2' do
          expect(page).to have_content items[1]['title']
        end
      end
    end
  end
end

Gurke.configure {|c| c.include Steps::CourseItem }
