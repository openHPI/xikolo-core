# frozen_string_literal: true

module Steps
  module Course
    module Syllabus
      Given 'several non-previewable and a previewable item were created' do
        send :'Given several items were created'
        send :'Given a video item with open mode was created'
        restricted_item = context.fetch :item
        context.assign :restricted_item, restricted_item
      end

      Given 'Open Mode is enabled' do
        set_xikolo_config('open_mode', {enabled: true, default: true})
      end

      When 'I click on an non-previewable item' do
        item = context.fetch :restricted_item
        click_on(item['title'])
      end

      When 'I hover over an non-previewable item' do
        restricted_item = context.fetch :restricted_item
        item = find 'p', text: restricted_item['title']
        item.hover
      end

      When 'I click on a previewable item' do
        open_mode_item = context.fetch :open_mode_item
        click_on(open_mode_item['title'])
      end

      Then 'I see the list of course items' do
        context.with :items do |items|
          items.each do |item|
            expect(page).to have_content item['title']
          end
        end
      end

      Then 'I do not see an infobox that informs me I visit the syllabus page in open mode' do
        send 'Then I see the list of course items'
        context.with :course do |course|
          expect(page).to_not have_content "The listed learning units belong to the course #{course['title']}"
        end
      end

      Then 'I see an infobox that informs me I visit the syllabus page in open mode' do
        context.with :course do |course|
          expect(page).to have_content "The listed learning units belong to the course #{course['title']}"
        end
      end

      Then 'I see a tooltip that informs me the item cannot be previewed' do
        expect(page).to have_content 'This learning unit cannot be previewed. Please enroll for the course to proceed.'
      end

      Then 'I see a non-previewable item' do
        context.with :course, :restricted_item do |course, item|
          expect(page).to have_current_path "/courses/#{course['course_code']}/items/#{short_uuid item['id']}"
          expect(page).to have_content item['title']
        end
      end

      Then 'I see the previewable item' do
        context.with :course, :open_mode_item do |course, item|
          expect(page).to have_current_path "/courses/#{course['course_code']}/items/#{short_uuid item['id']}"
          expect(page).to have_content item['title']
        end
      end
    end
  end
end

Gurke.configure {|c| c.include Steps::Course::Syllabus }
