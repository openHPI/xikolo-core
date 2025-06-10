# frozen_string_literal: true

module Steps
  module Video
    Given 'I have selected the video item for editing' do
      context.with :item do |item|
        within(:xpath, "//li[@data-id='#{item['id']}']") do
          find('.fa-pen-to-square').click
        end
      end
    end

    # The `course_video_url_template` below references the ID of a video
    # seeded in `integration/features/support/lib/initializers/integration_web.rb`.
    Given 'there is a configuration for transpipe' do
      context.with :course do |course|
        set_xikolo_config(
          'transpipe',
          {enabled: true,
          course_video_url_template: "https://transpipe.example.com/link/platform/courses/#{course['id']}/videos/00000003-3600-4444-9999-000000000001"}
        )
      end
    end

    When 'I fill out the minimal information for video item' do
      send :'When I add a title to the video item'
      send :'When I add a description to the video item'
      send :'When I add streams to the video item'
    end

    When 'I add a title to the video item' do
      fill_in 'Title', with: 'New Video Title'
    end

    When 'I edit the title to the video item' do
      fill_in 'Title', with: 'Edited Video Title'
    end

    When 'I add a description to the video item' do
      fill_markdown_editor 'Description', with: 'A **USELESS** but highlighted description!'
    end

    When 'I add an image to the description of the video item' do
      page.find('[contenteditable="true"]').click
      attach_file asset_path('mercedes.png'), visible: false, multiple: 'multiple'
    end

    When 'I add streams to the video item' do
      tom_select '_internetworking_intro_pip', from: 'Pip stream', search: true, clear: true
      tom_select '_internetworking_intro_lecturer', from: 'Lecturer stream', search: true, clear: true
      tom_select '_internetworking_intro_slides', from: 'Slides stream', search: true, clear: true
    end

    Then 'I see a message that the item was updated' do
      expect(page).to have_content 'The item was updated successfully.'
    end

    Then 'there is no dropzone for the subtitles' do
      expect(page).to have_content 'Subtitles'
      expect(page).to have_no_selector('.xui-upload[data-id="video_video_subtitles"]')
    end

    Then 'there is a link to add the subtitles via transpipe' do
      context.with :item do |item|
        expect(page).to have_link(
          'Manage subtitles in TransPipe',
          href: "https://transpipe.example.com/link/platform/courses/#{item['course_id']}/videos/#{item['content_id']}"
        )
      end
    end

    When 'I click the preview tab' do
      page.find('[aria-label="Preview"]').click
    end

    When 'I attach slides to the video' do
      attach_file 'Slides', asset_path('www_slides.pdf')
    end

    When 'I attach a transcript to the video' do
      attach_file 'Transcript', asset_path('www_slides.pdf') # TODO: attach something propper here
    end

    When 'I attach a reading material to the video' do
      attach_file 'Reading material', asset_path('www_slides.pdf') # TODO: attach something propper here
    end

    When 'I attach downloadable content' do
      send :'When I attach slides to the video'
      send :'When I attach a transcript to the video'
      send :'When I attach a reading material to the video'
    end

    When 'I attach subtitles to the video' do
      attach_file 'Subtitles', asset_path('valid_en.vtt')
    end

    When 'I save the video item' do
      click_on 'Create Item'
    end

    Then 'I see the attached subtitles in a specific language' do
      expect(find('span') {|value| value.text == 'en' }).to be_truthy
    end

    Then 'I should see a video keyboard hint' do
      expect(page).to have_content 'The player can be used'
    end

    When 'I click the hide the keyboard hint button' do
      click_on 'Don\'t show me this again.'
    end

    Then 'I should not see a video keyboard hint' do
      expect(page).to_not have_content <<~TEXT.strip
        The player can be used via the keyboard: [p] for \
        pause/play, left/right arrow key for seek and [f] \
        for Fullscreen.
      TEXT
    end

    When 'I save the changes of the video item' do
      sleep 0.5
      click_on 'Save item'
    end

    When 'I save and show the video item' do
      sleep 0.5
      click_on 'Save and show item'
    end

    When 'I select a video from the section navigation' do
      context.with :item do |item|
        within(:xpath, "//li[@data-id='#{item['id']}']") do
          find('.fa-eye').click
        end
      end
    end

    When 'I click the fallback button' do
      click_on 'alternative version'
    end

    When 'I start a new topic for the video' do
      find('#show_question_form').click
      fill_in 'Title', with: 'A Very (VERY) important question'
      fill_markdown_editor 'text', with: 'I have no idea what to ask.'
    end

    When 'I submit my video post' do
      click_on 'Post new topic'
    end

    Then 'the video description contains the URI of the image' do
      expect(page).to have_markdown_editor 'Description', with: <<~TEXT.strip
        Prof. Lena Babonsky introduces basic technical concepts of the World Wide Web \
        from a users perspective.![Insert image description]
      TEXT

      expect(page).to have_markdown_editor 'Description', with: '(s3://'
      expect(page).to have_markdown_editor 'Description', with: 'mercedes.png)'
      expect(page).not_to have_markdown_editor 'Description', with: 'http://s3'
    end

    Then 'the image is displayed' do
      displayed_description = page.find('.toastui-editor-md-preview.active')
      expect(displayed_description).to have_content <<~TEXT.strip
        Prof. Lena Babonsky introduces basic technical concepts of the \
        World Wide Web from a users perspective.
      TEXT
      expect(displayed_description).not_to have_content 's3://xikolo-video/videos/'
      expect(displayed_description).to have_css("img[src^='http'][src$='mercedes.png']")
    end

    Then 'there should be no video topic form' do
      expect(page).to_not have_selector('btn', text: 'Ask a question')
    end

    Then 'the item should offer the settings for items of type "video"' do
      expect(page).to have_content 'Description'
      expect(page).to have_content 'Pip stream'
      expect(page).to have_content 'Lecturer stream'
      expect(page).to have_content 'Slides stream'
      expect(page).to have_content 'Subtitles'
      expect(page).to have_content 'Slides'
      expect(page).to have_content 'Transcript'
      expect(page).to have_content 'Reading material'
    end

    Then 'the new video should be listed' do
      expect(page).to have_content 'New Video Title'
    end

    When 'I watch the created video' do
      page.find('.fa-eye').click
    end

    Then 'I should see the video in the Xikolo dual stream player' do
      expect(page).to have_xpath '//xm-player[contains(@class, "hydrated")]'
    end

    Then 'the video is rendered in the video player' do
      expect(page).to have_xpath '//xm-player[contains(@class, "hydrated")]'
    end

    Then "I should see the video's description" do
      expect(page).to have_content <<~TEXT.strip
        Prof. Lena Babonsky introduces basic technical \
        concepts of the World Wide Web from a users perspective.
      TEXT
    end

    Then "a new topic should be listed in the video's forum" do
      expect(page).to have_content '1 topic'
      expect(page).to have_content 'A Very (VERY) important question'
    end

    Then 'the forum should be ordered reverse chronological, newest on top' do
      find('#show_question_form').click
      fill_in 'Title', with: 'Second Question on Video'
      fill_markdown_editor 'text', with: 'My even more stupid question'
      send :'When I submit my video post'
      expect(page).to have_content 'Second Question on Video'
      expect(page.body.index('Second Question on Video')).to be <
                                                             page.body.index('A Very (VERY) important question')
    end

    Then 'I should see download buttons for all content' do
      click_on 'Download video'
      expect(page).to have_content 'Video (HD) as MP4'
      expect(page).to have_content 'Video (SD) as MP4'

      click_on 'Download additional material'
      expect(page).to have_content 'Presentation slides as PDF'
      expect(page).to have_content 'Transcription'

      expect(page).to have_selector '.fa-download'
    end

    Given 'the pip stream is listed' do
      expect(page).to have_content 'the_course_intro_pip2'
    end

    When 'I delete the pip stream' do
      find_all('[aria-label="More actions"]')[2].click
      within '[data-behaviour="menu-dropdown"]' do
        click_on 'Delete'
      end
      within_dialog do
        click_on 'Yes, sure'
      end
    end

    Then 'the pip stream is not listed any more' do
      expect(page).to_not have_content 'the_course_intro_pip2'
    end
  end
end

Gurke.configure {|c| c.include Steps::Video }
