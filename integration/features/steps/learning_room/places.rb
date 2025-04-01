# frozen_string_literal: true

module Steps
  module LearningRoom
    module Places
      def collab_space_list_path
        context.with :course do |course|
          "/courses/#{course['course_code']}/learning_rooms"
        end
      end

      def collab_space_path
        context.with :learning_room do |learning_room|
          "#{collab_space_list_path}/#{learning_room['id']}"
        end
      end

      def collab_space_edit_path
        "#{collab_space_path}/edit"
      end

      def collab_space_forum_path
        "#{collab_space_path}/pinboard"
      end

      Given 'I am on the collab space list' do
        visit collab_space_list_path
      end

      Given 'I am on the collab space page' do
        visit collab_space_path
      end

      When 'I visit the collab space page' do
        send :'Given I am on the collab space page'
      end

      Then 'I should be on the collab space page' do
        expect(page).to have_current_path collab_space_path
      end

      Given 'I am on the collab space administration page' do
        visit collab_space_edit_path
      end
    end
  end
end

Gurke.configure {|c| c.include Steps::LearningRoom::Places }
