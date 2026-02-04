# frozen_string_literal: true

require 'spec_helper'

describe 'Home: Course List', type: :system do
  let(:user) { build(:'account:user') }

  before do
    stub_user id: user['id'], features: {'course_list' => 'true'}
    Stub.request(:account, :get, "/users/#{user['id']}")
      .to_return Stub.json(user)
  end

  context 'with courses for all categories' do
    before do
      create(:course, status: 'active', start_date: 1.week.from_now)
      create(:course, status: 'active', start_date: 1.week.ago, end_date: 1.week.from_now)
      create(:course, status: 'active', start_date: 2.weeks.ago, end_date: 1.week.ago)
    end

    it 'shows courses grouped into categories' do
      visit '/courses'

      expect(page).to have_content 'Current courses'
      expect(page).to have_content 'Upcoming courses'
      expect(page).to have_content 'Self-paced courses'
    end
  end

  context 'without any current courses' do
    before do
      create(:course, status: 'active', start_date: 1.week.from_now)
      create(:course, status: 'active', start_date: 2.weeks.ago, end_date: 1.week.ago)
    end

    it 'hides empty categories' do
      visit '/courses'

      expect(page).to have_content 'Upcoming courses'
      expect(page).to have_content 'Self-paced courses'
      expect(page).to have_no_content 'Current courses'
    end
  end

  context 'with featured course' do
    before do
      create(:course, :active, :featured, title: 'Featured Course')
    end

    it 'shows the featured course' do
      visit '/courses'

      expect(page).to have_content 'Featured Course'
      expect(page).to have_css 'article.featured-course'
    end
  end

  describe 'filtering' do
    before do
      channel = create(:channel, title_translations: {'en' => 'Get Social!', 'de' => 'Get Social!'}, code: 'social')
      create(:course, status: 'active', title: 'Advanced Mumble Jumbo', lang: 'de', start_date: 1.week.ago, end_date: 1.week.from_now, abstract: 'Repetitive information.')
      course = create(:course, status: 'active', lang: 'de', title: 'An introduction to databases', start_date: 1.week.ago, end_date: 1.week.from_now, abstract: 'Repetitive information.')
      course.channels << channel

      cluster = create(:cluster, id: 'level', translations: {en: 'Level'})
      create(:cluster, id: 'topic')
      course.classifiers << create(:classifier, cluster:, title: 'beginner', translations: {en: 'Beginner'})
    end

    it 'can filter the list along multiple dimensions' do
      visit '/courses'

      # Relevant courses are showing when applying filters
      select 'Get Social!', from: 'Channel'
      select 'Beginner', from: 'Level'
      select 'German (Deutsch)', from: 'Language'

      expect(page).to have_content 'Current courses'
      expect(page).to have_content 'An introduction to databases'
      expect(page).to have_no_content 'Advanced Mumble Jumbo'

      # Applied filters are still selected
      expect(page).to have_select 'Channel', selected: 'Get Social!'
      expect(page).to have_select 'Language', selected: 'German (Deutsch)'
      expect(page).to have_select 'Level', selected: 'Beginner'

      # Show all courses after resetting
      click_on 'Reset all filters'

      expect(page).to have_content 'Current courses'
      expect(page).to have_content 'An introduction to databases'
      expect(page).to have_content 'Advanced Mumble Jumbo'
      expect(page).to have_select 'Channel', selected: 'All'
      expect(page).to have_select 'Level', selected: 'All'
      expect(page).to have_select 'Language', selected: 'All'

      # The reset button should be hidden if there is no filter applied
      expect(page).to have_no_link 'Reset all filters'

      pending 'Search reindexing of courses does not yet happen in xi-web'
      # Search term is searched in title, abstract and other fields...
      fill_in 'What would you like to learn?', with: 'databases'
      find("[aria-label='Search']").click

      expect(page).to have_content 'An introduction to databases'
      expect(page).to have_no_content 'Advanced Mumble Jumbo'

      # Reset is clearing search field
      click_on 'Reset all filters'

      expect(page).to have_content 'An introduction to databases'
      expect(page).to have_content 'Advanced Mumble Jumbo'
      expect(find_field('What would you like to learn?').text).to be_empty

      # Search and filter in combination:
      # Course not matching the applied dropdown filter but matching the text search should not be visible
      # Will also check for submit on enter of the search input
      select 'Get Social!', from: 'Channel'
      fill_in 'What would you like to learn?', with: 'Repetitive information.'
      find("input[type='search']").native.send_keys :return

      expect(page).to have_no_content 'Advanced Mumble Jumbo'
      expect(page).to have_content 'An introduction to databases'
    end
  end

  describe 'pagination of self-paced courses' do
    # rubocop:disable FactoryBot/ExcessiveCreateList
    before do
      create_list(:course, 12, title: 'Self-paced course on page 1', status: 'archive',
        start_date: DateTime.new(2017, 11, 1), end_date: DateTime.new(2017, 12, 1))
      create_list(:course, 12, title: 'Self-paced course on page 2', status: 'archive',
        start_date: DateTime.new(2016, 11, 1), end_date: DateTime.new(2016, 12, 1))
      create_list(:course, 12, title: 'Self-paced course on page 3', status: 'archive',
        start_date: DateTime.new(2015, 11, 1), end_date: DateTime.new(2015, 12, 1))
    end
    # rubocop:enable FactoryBot/ExcessiveCreateList

    it 'loads more courses' do
      visit '/courses'

      assert_text('Self-paced course on page 1', count: 12)

      expect(page).to have_no_content('Self-paced course on page 2')
      expect(page).to have_no_content('Self-paced course on page 3')

      click_on('Load more courses')

      # Scope to the course list content
      # to avoid matching the placeholder card
      within '#course-list__content' do
        # Use native Capybara assertion to wait for AJAX
        assert_text('Self-paced course on page 1', count: 12)
        assert_text('Self-paced course on page 2', count: 12)
      end

      expect(page).to have_no_content('Self-paced course on page 3')

      click_on('Load more courses')

      within '#course-list__content' do
        assert_text('Self-paced course on page 1', count: 12)
        assert_text('Self-paced course on page 2', count: 12)
        assert_text('Self-paced course on page 3', count: 12)
      end

      expect(page).to have_no_content 'Load more courses'
    end
  end
end
