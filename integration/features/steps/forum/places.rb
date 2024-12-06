# frozen_string_literal: true

module Steps::Forum::Places
  Given 'I am on the topic page' do
    context.with :forum_topic, :course do |topic, course|
      visit "/courses/#{course['course_code']}/question/#{topic['id']}"
    end
  end

  Given 'I am on the general forum' do
    context.with :course do |course|
      visit "/courses/#{course['course_code']}/pinboard"
      page.find('.pinboard-topics') # Wait for topics to load
    end
  end

  When 'I go to the general forum' do
    context.with :course do |course|
      visit "/courses/#{course['course_code']}"
      click_on 'Discussions'
      page.find('.pinboard-topics') # Wait for topics to load
    end
  end

  Then 'I should be on the topic page' do
    context.with :forum_topic, :course do |topic, course|
      expect(page).to have_current_path(
        "/courses/#{course['course_code']}/question/#{topic['id']}",
        ignore_query: true
      )
    end
    # make sure we actually loaded the page
    expect(page).to have_selector '.question-wrapper'
  end

  Then 'I am on the section forum page' do
    context.with :course, :section do |course, section|
      expect(page).to have_current_path(
        "/courses/#{course['course_code']}/sections/#{short_uuid section['id']}/pinboard"
      )
    end
  end
end
Gurke.configure {|c| c.include Steps::Forum::Places }
