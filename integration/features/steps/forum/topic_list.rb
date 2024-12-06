# frozen_string_literal: true

module Steps::Forum::TopicList
  When 'I open the second forum page' do
    within('.pinboard-pagination') do
      click_on '2'
    end
  end

  When 'I sort the topics by best vote' do
    page.select 'Best voted first', from: 'Sort by'
  end

  When 'I select the topics by technical issues' do
    find('select[name=pinboard_section]').select 'Technical Issues'
  end

  When 'I click on the clear filter button' do
    click_on 'Reset all filters'
  end

  When 'I fill in a search string' do
    page.fill_in 'Search', with: 'search'
    page.find('[aria-label="Search"]').click
  end

  def match_topic_texts(range, sort_by = nil)
    topics = context.fetch :forum_topics

    topics.sort_by! {|q| q[sort_by] } if sort_by
    titles = topics.reverse[range].pluck('title')

    # Wait for the topics to load
    expect(page).to have_content titles.first

    all('.question-title', count: titles.count).each do |title|
      expect(title.text).to eq titles.shift
    end
  end

  Then 'the first 25 topics are listed ordered by creation time' do
    match_topic_texts 0..24
  end

  Then 'the second 25 topics are listed ordered by creation time' do
    match_topic_texts 25..49
  end

  Then 'I have a button to start a new topic' do
    expect(page).to have_button('Start a new topic')
  end

  Then 'the first 25 topics are listed ordered by best votes' do
    match_topic_texts 0..24, 'votes'
  end

  def wait_for_ajax
    30.times do
      break if page.evaluate_script('jQuery.active').zero?

      sleep 0.5
    end

    sleep(2) # Wait for potential loading overlays to fade-out
  end
end

Gurke.configure {|c| c.include Steps::Forum::TopicList }
