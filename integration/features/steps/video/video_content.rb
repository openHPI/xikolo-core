# frozen_string_literal: true

module Steps
  module VideoContent
    Given 'a video item with downloadable content was created' do
      send :'Given I add an item'
      select 'Video', from: 'Type'
      send :'When I fill out the minimal information for video item'
      send :'When I attach downloadable content'
      send :'When I save the video item'
      send :'Then I should be on the course sections page'
    end
  end
end

Gurke.configure {|c| c.include Steps::VideoContent }
