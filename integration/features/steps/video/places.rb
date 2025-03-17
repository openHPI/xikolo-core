# frozen_string_literal: true

module Steps
  module Video
    module Places
      Given "I am in a video's context" do
        context.with :course, :section, :item do |course, _section, item|
          visit "/courses/#{course['course_code']}/items/#{short_uuid item['id']}"
        end
      end

      Given 'I am on the video list page' do
        visit '/videos'
      end

      Given 'I am on the video provider page' do
        visit '/admin/video_providers'
      end
    end
  end
end

Gurke.configure {|c| c.include Steps::Video::Places }
