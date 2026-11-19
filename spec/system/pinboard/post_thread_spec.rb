# frozen_string_literal: true

require 'spec_helper'

describe 'Pinboard: Post a topic', type: :system do
  let(:course) { create(:'course_service/course', :active) }
  let(:user) { create(:'account_service/user') }

  before do
    sign_in(user:)
    enroll_in(course)
  end

  it 'starts a topic in the general course context' do
    click_on 'Forum'
    click_on 'Start a new topic'

    fill_in 'Title', with: 'An important Question'
    fill_markdown_editor '[name="xikolo_pinboard_question[text]"]', use_selector: true, with: 'To Be, Or *Not* To Be'

    click_on 'Post new topic'

    within '#pinboard__content' do
      expect(page).to have_text 'An important Question'
    end
  end

  it 'starts a topic in a course section context' do
    section = create(:'course_service/section', course:)

    click_on 'Forum'

    find('select[name=pinboard_section]').select section.title

    click_on 'Start a new topic'

    fill_in 'Title', with: 'An important Question'
    fill_markdown_editor '[name="xikolo_pinboard_question[text]"]', use_selector: true, with: 'To Be, Or *Not* To Be'

    click_on 'Post new topic'

    expect(page).to have_current_path("/learn/#{course.course_code}/sections/#{short_uuid(section.id)}/pinboard")
    within '#pinboard__content' do
      expect(page).to have_text 'An important Question'
    end
  end

  it 'starts a topic in the technical issues context' do
    click_on 'Forum'

    find('select[name=pinboard_section]').select 'Technical Issues'

    click_on 'Start a new topic'

    fill_in 'Title', with: 'An important Question'
    fill_markdown_editor '[name="xikolo_pinboard_question[text]"]', use_selector: true, with: 'To Be, Or *Not* To Be'

    click_on 'Post new topic'

    find('select[name=pinboard_section]').select 'All discussions'

    expect(page).to have_no_link 'An important Question'

    find('select[name=pinboard_section]').select 'Technical Issues'

    expect(page).to have_link 'An important Question'
  end

  it 'selects tags in the forum' do
    tag = create(:'pinboard_service/explicit_tag', course_id: course.id, name: 'Homework')

    click_on 'Forum'
    click_on 'Start a new topic'

    fill_in 'Title', with: 'An important Question'
    fill_markdown_editor '[name="xikolo_pinboard_question[text]"]', use_selector: true, with: 'To Be, Or *Not* To Be'

    within 'form#new_xikolo_pinboard_question' do
      find('.ts-control input').click
      find('.ts-control input').send_keys(tag.name)
    end

    find('.ts-dropdown .ts-dropdown-content [data-selectable]', text: /#{Regexp.quote(tag.name)}/i).click

    within 'form#new_xikolo_pinboard_question' do
      find('.ts-control input').click
      find('.ts-control input').send_keys('new tag')
    end

    find('.ts-dropdown .ts-dropdown-content [data-selectable]', text: /new tag/i).click

    click_on 'Post new topic'

    expect(page).to have_text tag.name
    expect(page).to have_text 'new tag'
  end

  it 'starts a topic with a document attachment' do
    click_on 'Forum'
    click_on 'Start a new topic'

    fill_in 'Title', with: 'An important Question'
    fill_markdown_editor 'Text', with: 'To Be, Or *Not* To Be'
    attach_file 'Attachment', Rails.root.join('spec/fixtures/files/www_slides.pdf')

    click_on 'Post new topic'

    within '#pinboard__content' do
      expect(page).to have_text 'An important Question'
    end

    click_on 'An important Question'

    expect(page).to have_text 'To Be, Or Not To Be'
    expect(page).to have_link 'Download attachment'
  end

  it 'starts a topic with an image attachment' do
    click_on 'Forum'
    click_on 'Start a new topic'

    fill_in 'Title', with: 'An important Question'
    fill_markdown_editor 'Text', with: 'To Be, Or *Not* To Be'
    attach_file 'Attachment', Rails.root.join('spec/fixtures/files/redsandsforts.jpg')

    click_on 'Post new topic'

    within '#pinboard__content' do
      expect(page).to have_text 'An important Question'
    end

    click_on 'An important Question'

    expect(page).to have_text 'To Be, Or Not To Be'
    expect(page).to have_css('.qa-attachment a img')
  end

  it 'posts duplicate topic only once' do
    click_on 'Forum'
    click_on 'Start a new topic'

    fill_in 'Title', with: 'An important Question'
    fill_markdown_editor '[name="xikolo_pinboard_question[text]"]', use_selector: true, with: 'To Be, Or *Not* To Be'

    click_on 'Post new topic'

    click_on 'Start a new topic'

    fill_in 'Title', with: 'An important Question'
    fill_markdown_editor '[name="xikolo_pinboard_question[text]"]', use_selector: true, with: 'To Be, Or *Not* To Be'

    click_on 'Post new topic'

    within '#pinboard__content' do
      expect(page).to have_link('An important Question', count: 1)
    end
  end
end
