# frozen_string_literal: true

require 'spec_helper'

describe Home::CourseCard, type: :component do
  subject(:component) { described_class.new(Catalog::Course.find(course.id), enrollment:) }

  let(:course) { create(:course, :active) }
  let(:enrollment) { nil }

  def expect_level_icon(name)
    svg = Nokogiri::XML(Rails.root.join('app/assets/images/pixelarticons', "#{name}.svg").read)
    expect(page).to have_css("li svg path[d='#{svg.at_css('path')['d']}']")
  end

  it 'renders a single details link with the title, image, format, and language' do
    render_inline(component)

    expect(page).to have_css('article.course-card a', count: 1)
    expect(page).to have_link(course.title, href: "/learn/#{course.course_code}")
    expect(page).to have_css('h3', text: course.title)
    expect(page).to have_css('img[alt=""][loading="lazy"]')
    expect(page).to have_css('picture source', count: 4)
    expect(page).to have_text('Course')
    expect(page).to have_css('li[aria-label="Course language"]', text: 'English')
    expect(page).to have_no_css('button, progress, [data-behavior="expandable"]')
    expect(page).to have_no_text('Completed')
    expect(page).to have_no_text('Upcoming')
  end

  %w[course project workshop].each do |format|
    context "with format #{format}" do
      let(:course) { create(:course, :active, course_format: format) }

      it 'shows the translated format' do
        render_inline(component)

        expect(page).to have_text(I18n.t(:"course.formats.#{format}"))
      end
    end
  end

  context 'with a display start date in the future' do
    before { course.update!(display_start_date: 1.week.from_now) }

    it 'shows Upcoming even when the actual start date has passed' do
      render_inline(component)

      expect(page).to have_text('Upcoming')
    end
  end

  context 'with an actual start date in the future' do
    let(:course) { create(:course, :upcoming) }

    it 'falls back to the actual start date when the display date is absent' do
      render_inline(component)

      expect(page).to have_text('Upcoming')
    end

    it 'does not show Upcoming when the display date has passed' do
      course.update!(display_start_date: 1.week.ago)
      render_inline(component)

      expect(page).to have_no_text('Upcoming')
    end
  end

  context 'with an unpublished course' do
    let(:course) { create(:course, :upcoming, published: false, display_start_date: 1.week.from_now) }

    it 'does not show Upcoming even when its start dates are in the future' do
      render_inline(component)

      expect(page).to have_no_text('Upcoming')
    end
  end

  context 'with no start dates' do
    let(:course) { create(:course, :self_paced, start_date: nil, display_start_date: nil) }

    it 'does not show Upcoming' do
      render_inline(component)

      expect(page).to have_no_text('Upcoming')
    end
  end

  context 'with a completed enrollment' do
    let(:enrollment) { build(:enrollment, course:, completed: true) }

    it 'shows completion as information without adding an action' do
      render_inline(component)

      expect(page).to have_text('Completed')
      expect(page).to have_css('a', count: 1)
    end
  end

  context 'with an incomplete enrollment' do
    let(:enrollment) { build(:enrollment, course:, completed: false) }

    it 'does not show the completion badge' do
      render_inline(component)

      expect(page).to have_no_text('Completed')
    end
  end

  context 'with persisted progress' do
    let(:stored_enrollment) { create(:enrollment, course:, completed:) }
    let(:enrollment) { CourseService::Enrollment.with_evaluation.find(stored_enrollment.id) }
    let(:completed) { false }
    let(:percentage) { 33_33 }

    before do
      create(:'course_service/course_progress', course:, user_id: stored_enrollment.user_id,
        visits_percentage_fpoints: percentage, points_percentage_fpoints: 80_00)
    end

    it 'shows visit progress below the image without another action or visible percentage' do
      render_inline(component)

      expect(page).to have_css('figure + progress[value="33.33"][max="100"][aria-label="Course progress"]')
      expect(page).to have_css('a', count: 1)
      expect(page).to have_no_text('%')
    end

    context 'with all items visited' do
      let(:percentage) { 100_00 }

      it 'shows full progress without marking the enrollment as completed' do
        render_inline(component)

        expect(page).to have_css('progress[value="100.0"]')
        expect(page).to have_no_text('Completed')
      end
    end

    context 'with manual completion' do
      let(:completed) { true }

      it 'keeps the actual visit progress alongside the completion badge' do
        render_inline(component)

        expect(page).to have_css('progress[value="33.33"]')
        expect(page).to have_text('Completed')
      end
    end
  end

  context 'without a persisted progress record' do
    let(:stored_enrollment) { create(:enrollment, course:) }
    let(:enrollment) { CourseService::Enrollment.with_evaluation.find(stored_enrollment.id) }

    it 'shows an empty determinate progress bar' do
      render_inline(component)

      expect(page).to have_css('progress[value="0.0"][max="100"]')
    end
  end

  context 'with topics' do
    let(:topic_cluster) { create(:cluster, id: 'topic') }
    let(:topic_count) { 0 }

    before do
      topic_count.times do |index|
        title = "Topic #{index + 1}"
        course.classifiers << create(:classifier, cluster: topic_cluster, title:, translations: {en: title})
      end
    end

    it 'omits the topics list when there are no topics' do
      render_inline(component)

      expect(page).to have_no_css('ul[aria-label="Topics"]')
      expect(page).to have_css('.x-card-body > h3:first-child', text: course.title)
      expect(page).to have_css('li[aria-label="Course language"]', text: 'English')
    end

    context 'with exactly three topics' do
      let(:topic_count) { 3 }

      it 'shows all three topics without an overflow badge' do
        render_inline(component)

        expect(page).to have_css('ul[aria-label="Topics"] li', count: 3)
        (1..3).each do |index|
          expect(page).to have_css('ul[aria-label="Topics"] li', exact_text: "Topic #{index}", normalize_ws: true)
        end
      end
    end

    [4, 5].each do |count|
      context "with #{count} topics" do
        let(:topic_count) { count }

        it 'shows the first three topics and the remaining count as a fourth badge' do
          topics = Catalog::Course.find(course.id).classifiers('topic')
          render_inline(component)

          badges = page.all('ul[aria-label="Topics"] li').map {|badge| badge.text(normalize_ws: true) }
          expect(badges).to eq([*topics.first(3), "+#{count - 3}"])
          expect(page.find('ul[aria-label="Topics"] li:last-child')['title']).to eq(topics.drop(3).join(', '))
        end
      end
    end
  end

  context 'with classifiers' do
    let(:topic) { create(:cluster, id: 'topic') }
    let(:level) { create(:cluster, id: 'level') }

    before do
      course.classifiers << create(:classifier, cluster: topic, title: 'programming', translations: {en: 'Programming', de: 'Programmieren'})
      course.classifiers << create(:classifier, cluster: level, title: 'Beginner', translations: {en: 'Beginner', de: 'Einstieg'})
    end

    it 'shows topic badges and a separate level item' do
      render_inline(component)

      expect(page).to have_css('ul[aria-label="Topics"] li', text: 'Programming')
      expect(page).to have_css('li[aria-label="Level"]', text: 'Beginner')
      expect_level_icon('cellular-signal-1')
    end

    it 'localizes classifier labels without changing the level icon' do
      I18n.with_locale(:de) { render_inline(component) }

      expect(page).to have_text('Programmieren')
      expect(page).to have_text('Einstieg')
      expect(page).to have_css('li[aria-label="Kurssprache"]', text: 'Englisch')
      expect_level_icon('cellular-signal-1')
    end

    it 'omits classifiers from invisible clusters' do
      topic.update!(visible: false)
      level.update!(visible: false)
      render_inline(component)

      expect(page).to have_no_text('Programming')
      expect(page).to have_no_text('Beginner')
    end

    {'Intermediate' => 'cellular-signal-2', 'Expert' => 'cellular-signal-3', 'Other' => 'cellular-signal-0'}.each do |title, icon|
      it "uses the #{icon} icon for #{title}" do
        course.classifiers.find_by!(cluster: level).update!(title:)
        render_inline(component)

        expect_level_icon(icon)
      end
    end
  end
end
