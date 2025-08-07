# frozen_string_literal: true

module Steps
  module Forum
    Given 'I fill in a topic title and text' do
      fill_in 'Title', with: 'An important Question'
      fill_markdown_editor '[name="xikolo_pinboard_question[text]"]', use_selector: true, with: 'To Be, Or *Not* To Be'
    end

    Given 'I start a new topic' do
      click_on 'Start a new topic'
      send :'Given I fill in a topic title and text'
    end

    When 'I start a new video topic' do
      page.find('#show_question_form').click
      send :'Given I fill in a topic title and text'
      send :'When I submit my post'
    end

    Given 'I start a new topic with a document attachment' do
      click_on 'Start a new topic'

      fill_in 'Title', with: 'An important Question'
      fill_markdown_editor 'Text', with: 'To Be, Or *Not* To Be'
      attach_file 'Attachment', asset_path('www_slides.pdf')
    end

    Given 'I start a new topic with a document attachment' do
      click_on 'Start a new topic'

      fill_in 'Title', with: 'An important Question'
      fill_markdown_editor 'Text', with: 'To Be, Or *Not* To Be'
      attach_file 'Attachment', asset_path('www_slides.pdf')
    end

    Given 'I start a new topic with an image attachment' do
      click_on 'Start a new topic'

      fill_in 'Title', with: 'An important Question'
      fill_markdown_editor 'Text', with: 'To Be, Or *Not* To Be'
      attach_file 'Attachment', asset_path('redsandsforts.jpg')
    end

    Given 'I start a new forum topic' do
      click_on 'Start a topic'

      fill_in 'Title', with: 'An important Topic'
      fill_markdown_editor 'Text', with: 'To Be, Or *Not* To Be'
    end

    Given 'I am the owner of the topic' do
      context.assign :user, context.fetch(:forum_topic_author)
    end

    Given 'I select the posted topic' do
      context.with :forum_topic do |topic|
        click_on topic['title']
      end
    end

    When 'I select the posted topic' do
      send :'Given I select the posted topic'
    end

    Given 'I select a topic' do
      page.find('.question-title', match: :first).click
    end

    Given 'I am reading a forum topic' do
      send :'Given I am logged in'
      send :'Given I am on the general forum'
      send :'Given I select the posted topic'
    end

    def read_topic
      course = context.fetch :course
      visit "/courses/#{course['course_code']}"
      click_on 'Discussions'
      context.with :forum_topic do |topic|
        click_on topic['title']
      end
    end

    Given 'I read the topic for the first time' do
      read_topic
    end

    When(/^I read the topic/) do
      read_topic
    end

    Given 'I am reading a topic as teacher' do
      send :'Given I am logged in as a course admin'
      send :'Given I am on the general forum'
      send :'Given I select the posted topic'
    end

    Given 'I comment the answer' do
      within('div.mt30 .qa-box') do
        click_on 'Add comment'
      end
    end

    Given 'I select an existing tag' do
      context.with :forum_tag do |tag|
        within 'form#new_xikolo_pinboard_question' do
          tom_select tag['name'], from: 'Tags'
        end
      end
    end

    Given 'I create a new tag' do
      within 'form#new_xikolo_pinboard_question' do
        tom_select 'new tag', from: 'Tags', search: true
      end
      context.assign :new_forum_tag_name, 'new tag'
    end

    Given 'all topics are unread' do
      expect(page).to have_selector('.pinboard-question.unread', count: 1)
    end

    Given 'I change to the technical issues' do
      find('select[name=pinboard_section]').select 'Technical Issues'
    end

    Given 'the topic belongs to a section' do
      send :'When I edit the topic'
      send :"When I change the topic's section"
    end

    Given 'the topic is closed' do
      send :'When I close a topic'
    end

    Then 'all topics are unread' do
      send :'Given all topics are unread'
    end

    When 'I go back to the overview' do
      click_on 'All discussions'
    end

    When 'I delete a topic' do
      within '.moderator' do
        click_on 'Delete'
      end
      within_dialog do
        click_on 'Yes, sure'
      end
    end

    When 'I delete the answer' do
      within '.qa-box.answer' do
        click_on 'delete'
      end
      within_dialog do
        click_on 'Yes, sure'
      end
    end

    When 'I delete the topic comment' do
      within '.question-comments' do
        click_on 'delete'
      end
      within_dialog do
        click_on 'Yes, sure'
      end
    end

    When 'I delete the answer comment' do
      within '.answer-comments' do
        click_on 'delete'
      end
      within_dialog do
        click_on 'Yes, sure'
      end
    end

    When 'I close a topic' do
      click_on 'Close'
      within_dialog do
        click_on 'Yes, sure'
      end
    end

    When 'I reopen a topic' do
      click_on 'Reopen'
      within_dialog do
        click_on 'Yes, sure'
      end
    end

    When 'I open the general forum' do
      send :'Given I am on the general forum'
    end

    When 'I submit an answer' do
      fill_markdown_editor '#markdown-input-text-answer-', use_selector: true,
        with: 'A **USELESS** but highlighted answer!'
      click_on 'Post reply'
    end

    When 'I submit an answer with an attached document' do
      fill_markdown_editor '#markdown-input-text-answer-', use_selector: true,
        with: 'A **USELESS** but highlighted answer!'
      attach_file 'Attachment', asset_path('www_slides.pdf'), id: 'xikolo_pinboard_answer_attachment'
      click_on 'Post reply'
    end

    When 'I submit an answer with an attached image' do
      fill_markdown_editor '#markdown-input-text-answer-', use_selector: true,
        with: 'A **USELESS** but highlighted answer!'
      attach_file 'Attachment', asset_path('redsandsforts.jpg'), id: 'xikolo_pinboard_answer_attachment'
      click_on 'Post reply'
    end

    When 'I submit my comment' do
      fill_markdown_editor "[name='xikolo_pinboard_comment[text]']", use_selector: true,
        with: 'Good question'
      click_on 'Send comment'
    end

    When 'I submit my post' do
      click_on 'Post new topic'
    end

    When 'I submit my topic' do
      click_on 'Post new topic'
    end

    When 'I post a topic' do
      send :'When I start a new topic'
      send :'When I submit my post'
    end

    When 'I post a duplicate' do
      send :'When I post a topic'
      send :'When I post a topic'
    end

    When 'I mark a solution as working' do
      find('.accept').click
    end

    When 'I click the "edit" button of a specific post' do
      page.find('.question-edit a').click
    end

    When 'I click the "edit" button of a specific comment' do
      page.find('.comment-edit').click
    end

    When 'I click the "edit" button of an answer' do
      page.find('.answer-edit').click
    end

    When 'I edit the topic' do
      page.find('.question-edit').click
    end

    When 'I update the topic' do
      click_on 'Save changes'
    end

    When 'I update the topic\'s title' do
      fill_in 'xikolo_pinboard_question[title]', with: 'New title'
      send :'When I update the topic'
    end

    When 'I change the topic\'s section' do
      context.with :section do |section|
        select section['title'], from: 'Move to'
      end
      send :'When I update the topic'
    end

    When 'I move the topic to Technical Issues' do
      select 'Technical Issues', from: 'Move to'
      send :'When I update the topic'
    end

    When 'I remove the topic\'s section' do
      select 'General', from: 'Move to'
      send :'When I update the topic'
    end

    When 'I edit the video topic' do
      click_on 'View or reply'
      send :'When I edit the topic'
    end

    When 'I select the fifth topic' do
      topics = context.fetch :forum_topics
      context.assign :forum_topic, topics[-5]
      click_on topics[-5]['title']
    end

    When 'I mark the topic sticky' do
      context.with :forum_topic do |topic|
        send :'When I click the "edit" button of a specific post'
        within "#question-edit-#{topic['id']}" do
          page.find('label', text: 'Sticky').click
        end
        send :'When I update the topic'
        sleep(1)
      end
    end

    When 'I mark the new topic sticky' do
      within '#new_xikolo_pinboard_question' do
        page.find('label', text: 'Sticky').click
      end
    end

    When 'I start a new topic' do
      send :'Given I start a new topic'
    end

    When 'I click on a tag' do
      context.with :forum_tag do |tag|
        find('.tag-button', text: tag['name'], match: :first).click
      end
    end

    When 'I cancel editing' do
      page.find('.cancel-post').click
    end

    When 'I report the topic' do
      page.find('[data-test-id="question-report"]').click
      within_dialog do
        click_on 'Yes, sure'
      end
    end

    When 'I report the answer' do
      page.find('[data-test-id="answer-report"]').click
      within_dialog do
        click_on 'Yes, sure'
      end
    end

    When 'I report the comment' do
      page.find('[data-test-id="comment-report"]').click
      within_dialog do
        click_on 'Yes, sure'
      end
    end

    When 'I report the topic twice' do
      send :'When I report the topic'
      send :'When I report the topic'
    end

    When 'three students report the topic' do
      3.times do
        send :'Given I am logged in as some other user'
        send :'Given I am on the topic page'
        send :'When I report the topic'
      end
      send :'Given I am on the topic page'
    end

    When 'I block the topic' do
      click_on 'block'
    end

    When 'I unblock the topic' do
      click_on 'review'
    end

    When 'the topic was blocked' do
      send :'When three students report the topic'
    end

    Then 'the topic should be blocked' do
      within('.question-title') do
        expect(page).to have_content '[Blocked]'
      end
    end

    Then 'the topic should not be blocked' do
      expect(page).to_not have_content '[Blocked]'
      context.with :forum_topic do |topic|
        expect(page).to have_content topic['title']
      end
    end

    Then 'an email should be sent to all course admins' do
      context.with :course_admins do |admins|
        admins.each do |admin|
          open_email fetch_emails(
            to: admin['email'],
            subject: 'Please review blocked pinboard item'
          ).first
          expect(page).to have_content 'an item was automatically blocked. Please review!'
        end
      end
    end

    Then 'the link in the email should refer to the topic' do
      click_on 'Click here to review!'
      context.with :course, :forum_topic do |course, topic|
        expect(page).to have_current_path(
          "/courses/#{course['course_code']}/question/#{topic['id']}",
          ignore_query: true
        )
      end
    end

    Then 'I see a reporting success notice' do
      expect(page).to have_notice 'Your report was received successfully'
    end

    Then 'I see a reporting failure notice' do
      expect(page).to have_notice 'There was an error reporting this post'
    end

    Then 'all topics are read' do
      expect(page).to have_selector '.pinboard-question'
      expect(page).to_not have_selector '.pinboard-question.unread'
    end

    Then 'my topic should be listed on the forum' do
      expect(page.find('.pinboard-topics')).to have_link 'An important Question'
    end

    Then 'my topic should be listed only once' do
      expect(page.find('.pinboard-topics')).to have_link 'An important Question', count: 1
    end

    Then 'my topic should not be listed on the forum' do
      find('select[name=pinboard_section]').select 'All discussions'
      expect(page.find('.pinboard-topics')).not_to have_link 'An important Question'
    end

    Then 'my topic should be listed on the technical issues forum' do
      find('select[name=pinboard_section]').select 'Technical Issues'
      expect(page.find('.pinboard-topics')).to have_link 'An important Question'
    end

    Then 'my video topic should be listed on the page' do
      expect(page).to have_content 'An important Question'
    end

    Then 'my topic should display the selected tags' do
      context.with :forum_tag do |tag|
        expect(page).to have_content tag['name']
      end
      if (new_tag_name = context.fetch(:new_forum_tag_name))
        expect(page).to have_content new_tag_name
      end
    end

    Then 'my topic is listed on the forum' do
      expect(page).to have_link 'An important Question'
    end

    Then 'my answer is listed in the topic\'s answer list' do
      expect(page).to have_content 'A USELESS but highlighted answer!'
    end

    Then 'I see the uploaded document attachment' do
      expect(page).to have_link 'Download attachment'
    end

    Then 'I see the uploaded image attachment' do
      expect(page).to have_selector('.qa-attachment a img')
    end

    Then 'my comment is listed in the topic\'s comment list' do
      expect(page).to have_content 'Good question'
    end

    Then 'the answer should be marked as working' do
      expect(page.find('tr.accepted')).to have_text 'I think I know the answer: 42!'
    end

    Then 'I can create a new answer' do
      expect(page).to have_content 'Reply'
    end

    Then 'I cannot create a new answer' do
      expect(page).to_not have_content 'Reply'
    end

    Then 'I can see the add comment button' do
      expect(page).to have_content 'Add comment'
    end

    Then 'I cannot see the add comment button' do
      expect(page).to_not have_content 'Add comment'
    end

    Then 'I can edit the topic text and save my changes' do
      context.with :forum_topic do
        fill_in 'Title', with: 'Edited title'
        fill_markdown_editor('#markdown-input-text-edit-question',
          use_selector: true, with: 'Edited text')
        send :'When I update the topic'
      end
    end

    Then 'the title and text of the post are changed' do
      expect(page).to have_content 'Edited title'
      expect(page).to have_content 'Edited text'
    end

    Then 'I can edit the comment text and save my changes' do
      context.with :forum_topic do |topic|
        fill_markdown_editor("#markdown-input-text-edit-comment-Question-#{topic['id']}",
          use_selector: true, with: 'Edited comment')
        click_on 'Save changes'
      end
    end

    Then 'the text of the comment is changed' do
      expect(page).to have_content 'Edited comment'
    end

    Then 'my topic should be marked as read' do
      expect(page).to have_selector '.pinboard-question'
      expect(page).to_not have_selector '.pinboard-question.unread'
    end

    Then 'I can look at my topic' do
      click_on 'An important Question'
      expect(page).to have_content('To Be, Or Not To Be')
    end

    Then 'the topic is not worked on' do
      within '.question-shortinfo.views' do
        expect(page).to have_content '1'
      end
      within '.question-shortinfo.answers' do
        expect(page).to have_content '0'
      end
      within '.votes' do
        expect(page).to have_content '0'
      end
    end

    Then 'the reply count should be two' do
      within '.question-shortinfo.answers' do
        expect(page).to have_content '2'
      end
    end

    Then 'the votes count should change' do
      within '.votes' do
        expect(page).to have_content '1'
      end
    end

    Then 'I should not see the new topic button' do
      expect(page).to_not have_content 'Start a new topic'
    end

    Then 'I should see the reopen button' do
      expect(page).to have_content 'Reopen'
    end

    Then 'I should see the close button' do
      expect(page).to have_content 'Close'
    end

    Then 'I should see a forum is locked message' do
      expect(page).to have_content 'The discussions for this course are read-only'
    end

    Then 'I should see a section is locked message' do
      context.with :section do |section|
        expect(page).to have_content "The discussions for the section \"#{section['title']}\" are read-only"
      end
    end

    Then 'I should see a entry is closed message' do
      expect(page).to have_content 'The entry was closed and is now read-only'
    end

    Then 'the topic should be visible' do
      context.with :forum_topic do |topic|
        expect(page).to have_content topic['title']
      end
    end

    Then 'the topic should not be visible' do
      context.with :forum_topic do |topic|
        expect(page).to_not have_content topic['title']
      end
    end

    Then 'I can\'t see the topic\'s content' do
      context.with :forum_topic do |topic|
        expect(page).to_not have_content topic['text']
      end
    end

    Then 'I can see the topic\'s content' do
      context.with :forum_topic do |topic|
        expect(page).to have_content topic['text']
      end
    end

    Then 'I can\'t answer the topic' do
      expect(page).to_not have_button 'Add reply'
      expect(page).to_not have_button 'Add comment'
    end

    Then 'I can answer the topic' do
      expect(page).to have_button 'Add reply'
    end

    Then 'I can comment the answer' do
      expect(page).to have_button 'Add comment'
    end

    Then 'the answer should not be visible' do
      context.with :forum_topic_answer do |answer|
        expect(page).to_not have_content answer['text']
      end
    end

    Then 'the topic comment should not be visible' do
      context.with :forum_topic_comment do |comment|
        expect(page).to_not have_content comment['text']
      end
    end

    Then 'the answer comment should not be visible' do
      context.with :forum_answer_comment do |comment|
        expect(page).to_not have_content comment['text']
      end
    end

    Then 'the topic belongs to that section' do
      context.with :section do |section|
        expect(page.find('.pinboard-breadcrumbs')).to have_content section['title']
      end
    end

    Then 'the topic belongs to Technical Issues' do
      expect(page.find('.pinboard-breadcrumbs')).to have_content 'Technical Issues'
    end

    Then 'the topic belongs to no section' do
      context.with :section do |section|
        within '.pinboard-breadcrumbs' do
          expect(page).not_to have_content section['title']
        end
      end
    end

    Then 'the topic should have the new title' do
      expect(page).to have_content('New title')
    end

    Then 'the topic should have closed icon' do
      expect(page).to have_content('Closed')
    end

    When 'I open the video topic' do
      click_on 'View or reply'
    end

    Then 'my topic belongs to the correct section and item' do
      expect(page).to have_content(context.fetch(:section)['title'])
      expect(page).to have_content(context.fetch(:item)['title'])
    end

    Then 'the sticky topic should be on top' do
      first = page.all('.pinboard-question').first
      # expect(first).to have_selector '.sticky'
      context.with :forum_topic do |topic|
        expect(first).to have_content topic['title']
      end
      within first do
        expect(page).to have_selector '.fa-thumbtack'
      end
    end

    Then 'the new topic should be sticky' do
      expect(page.find('.pinboard-question', match: :first)[:class]).to match(/(\s|^)sticky(\s|$)/)
    end

    Then 'I should not be able to mark it sticky' do
      expect(page).to_not have_content 'Sticky'
    end

    Then 'I only see topic with that tag' do
      context.with :forum_tag do |tag|
        page.all(:css, '.pinboard_question .tags').each do |el| # rubocop:disable Rails/FindEach
          expect(el).to have_content tag['name']
        end
      end
    end

    Then 'I should not be able to delete the post' do
      expect(page).to_not have_content 'delete'
    end

    Then 'I should not see the edit form' do
      expect(page).to_not have_selector '.edit-post'
    end

    Then "the first answer doesn't look any different" do
      expect(page).to have_css('.qa-answer') # just wait
      answer = find('.qa-answer', text: /First answer/)
      expect(answer).to_not match_css '.unread'
    end

    Then "the first comment doesn't look any different" do
      expect(page).to have_css('.comment-post') # just wait
      comment = find('.comment-post', text: /First comment/)
      expect(comment).to_not match_css '.unread'
    end

    Then(/^the second answer is highlighted/) do
      expect(page).to have_css('.qa-answer') # just wait
      answer = find('.qa-answer', text: /Another answer/)
      expect(answer).to match_css '.unread'
    end

    Then(/^the second comment is highlighted/) do
      expect(page).to have_css('.comment-post') # just wait
      comment = find('.comment-post', text: /Another comment/)
      expect(comment).to match_css '.unread'
    end
  end
end

Gurke.configure {|c| c.include Steps::Forum }
