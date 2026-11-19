# frozen_string_literal: true

require 'spec_helper'

describe Navigation::TableOfContents, type: :component do
  subject(:component) do
    described_class.new
  end

  context 'provided with sections' do
    it 'renders sections' do
      render_inline(component) do |toc|
        toc.with_section(text: 'Section 1', link: {href: '/section_1'})
        toc.with_section(text: 'Section 2', link: {href: '/section_2'})
      end

      # sections should be rendered in a single list
      expect(page).to have_css('ul', count: 1)

      expect(page).to have_link('Section 1', href: '/section_1')
      expect(page).to have_link('Section 2', href: '/section_2')
    end
  end

  context 'provided with units' do
    it 'renders sections and its units' do
      render_inline(component) do |toc|
        toc.with_section(text: 'Section 1', link: {href: '/section_1'}) do |section|
          section.with_segment_unit(text: 'Unit 1', link: {href: '/unit_1'})
          section.with_segment_unit(text: 'Unit 2', link: {href: '/unit_2'})
        end
      end

      # units are rendered in a separate list, collapsed by default
      expect(page).to have_css('ul', count: 2, visible: :all)

      # sections with units expand in place instead of linking to the section
      expect(page).to have_css('details > summary', text: 'Section 1')
      expect(page).to have_no_link('Section 1')
      expect(page).to have_link('Unit 1', href: '/unit_1', visible: :hidden)
      expect(page).to have_link('Unit 2', href: '/unit_2', visible: :hidden)
    end
  end

  context 'with completed units' do
    it 'marks the completed units only' do
      render_inline(component) do |toc|
        toc.with_section(text: 'Section 1', link: {href: '/section_1'}, active: true) do |section|
          section.with_segment_unit(text: 'Unit 1', link: {href: '/unit_1'}, completed: true)
          section.with_segment_unit(text: 'Unit 2', link: {href: '/unit_2'})
        end
      end

      completed_unit = page.find_link('Unit 1')
      expect(completed_unit).to have_css('[aria-hidden=true] svg')
      expect(completed_unit).to have_css('.sr-only', exact_text: 'Completed')
      expect(page.find_link('Unit 2')).to have_no_css('.sr-only', exact_text: 'Completed')
    end
  end

  context 'with section progress' do
    it 'shows the number of completed units' do
      render_inline(component) do |toc|
        toc.with_section(text: 'Section 1', link: {href: '/section_1'}, progress: {completed: 1, total: 2}) do |section|
          section.with_segment_unit(text: 'Unit 1', link: {href: '/unit_1'}, completed: true)
          section.with_segment_unit(text: 'Unit 2', link: {href: '/unit_2'})
        end
      end

      summary = page.find('details > summary', text: 'Section 1')
      expect(summary).to have_css('[aria-hidden=true]', exact_text: '1 / 2')
      expect(summary).to have_css('.sr-only', exact_text: '1 of 2 completed')
    end
  end

  context 'with an active section' do
    it 'expands the active section only' do
      render_inline(component) do |toc|
        toc.with_section(text: 'Section 1', link: {href: '/section_1'}) do |section|
          section.with_segment_unit(text: 'Unit 1', link: {href: '/unit_1'})
        end
        toc.with_section(text: 'Section 2', link: {href: '/section_2'}, active: true) do |section|
          section.with_segment_unit(text: 'Unit 2', link: {href: '/unit_2'})
        end
      end

      expect(page).to have_css('details:not([open]) > summary', text: 'Section 1')
      expect(page).to have_css('details[open] > summary', text: 'Section 2')
    end
  end

  context 'provided with sub sections' do
    it 'renders sections and its sub sections' do
      render_inline(component) do |toc|
        toc.with_section(text: 'Section 1', link: {href: '/section_1'}) do |section|
          section.with_segment_section(text: 'Sub Section', link: {href: '/sub_section'})
        end
      end

      # sub sections are rendered in a separate list, collapsed by default
      expect(page).to have_css('ul', count: 2, visible: :all)

      expect(page).to have_css('details > summary', text: 'Section 1')
      expect(page).to have_link('Sub Section', href: '/sub_section', visible: :hidden)
    end
  end

  describe '.for_course' do
    subject(:toc) do
      described_class.for_course(
        user:, course:, sections: course.sections.not_alternative,
        current_section: nil, current_item: nil, context: vc_test_controller.view_context
      )
    end

    let(:course) { create(:'course_service/course', :active, course_code: 'the-course') }
    let(:section) { create(:'course_service/section', course:, title: 'Week 1') }
    let(:other_section) { create(:'course_service/section', course:, title: 'Week 2', position: 2) }
    let(:user) { instance_double(CurrentUser::User, allowed?: false, logged_in?: true, id: SecureRandom.uuid) }

    before do
      create(:'course_service/item', section:, title: 'Video', content_type: 'video', open_mode: true,
        published: true)
      create(:'course_service/item', section:, title: 'Upcoming', content_type: 'rich_text',
        start_date: 1.day.from_now, published: true)
      create(:'course_service/item', section:, title: 'Bonus', content_type: 'rich_text',
        deemphasized_in_nav: true, published: true)
      create(:'course_service/item', section:, title: 'Unpublished', published: false)
      create(:'course_service/item', section: other_section, title: 'Quiz', content_type: 'quiz',
        exercise_type: 'main', published: true)
    end

    def unit(title)
      page.find(:xpath, "//li[./*/span[normalize-space()='#{title}']]", visible: :all)
    end

    it 'renders the published items of all sections' do
      render_inline(toc)

      expect(page).to have_css('li', text: 'Video', visible: :all)
      expect(page).to have_css('li', text: 'Upcoming', visible: :all)
      expect(page).to have_css('li', text: 'Bonus', visible: :all)
      expect(page).to have_css('li', text: 'Quiz', visible: :all)
      expect(page).to have_no_text('Unpublished')
    end

    context 'for an enrolled user' do
      before do
        allow(user).to receive(:allowed?).with('course.content.access.available').and_return(true)
      end

      it 'locks the items outside their dates only' do
        render_inline(toc)

        expect(unit('Video')).to have_link('Video', visible: :all)
        expect(unit('Quiz')).to have_link('Quiz', visible: :all)
        expect(unit('Upcoming')).to have_no_link(visible: :all)
        expect(unit('Upcoming').find('div', visible: :all)[:class].split)
          .to include('text-base-content/60', 'cursor-not-allowed')
      end

      context 'with a quiz whose submission deadline has passed' do
        before do
          create(:'course_service/item', section: other_section, title: 'Expired quiz', content_type: 'quiz',
            exercise_type: 'main', submission_deadline: 1.day.ago, published: true)
        end

        it 'shows the quiz as locked, but links its page about the passed deadline' do
          render_inline(toc)

          link = unit('Expired quiz').find('a', visible: :all)
          expect(link[:class].split).to include('text-base-content/60')
          expect(link[:class].split).not_to include('cursor-not-allowed')
        end

        context 'when the user reactivated the course' do
          before do
            account = create(:'account_service/user')
            allow(user).to receive(:id).and_return(account.id)
            create(:'course_service/enrollment', :reactivated, course:, user_id: account.id)
          end

          it 'unlocks the quiz until the forced submission date' do
            render_inline(toc)

            expect(unit('Expired quiz').find('a', visible: :all)[:class].split).not_to include('text-base-content/60')
          end
        end
      end

      context 'with an exam' do
        let(:account) { create(:'account_service/user') }
        let(:exam) do
          create(:'course_service/item', section: other_section, title: 'Exam', content_type: 'quiz',
            exercise_type: 'exam', published: true,
            content_id: create(:'quiz_service/quiz', :with_valid_question_pool).id)
        end

        before do
          exam
          allow(user).to receive(:id).and_return(account.id)
        end

        it 'shows the exam as locked, but links its page about the required course progress' do
          render_inline(toc)

          link = unit('Exam').find('a', visible: :all)
          expect(link[:class].split).to include('text-base-content/60')
          expect(link[:class].split).not_to include('cursor-not-allowed')
        end

        context 'when the user reached the required course progress' do
          before do
            create(:'course_service/course_progress', course:, user_id: account.id, visits_percentage_fpoints: 8_000)
          end

          it 'unlocks the exam' do
            render_inline(toc)

            expect(unit('Exam').find('a', visible: :all)[:class].split).not_to include('text-base-content/60')
          end
        end

        context 'when the user already submitted the exam' do
          before { create(:'course_service/result', item: exam, user_id: account.id, dpoints: 10) }

          it 'unlocks the exam for its results' do
            render_inline(toc)

            expect(unit('Exam').find('a', visible: :all)[:class].split).not_to include('text-base-content/60')
          end
        end
      end

      it 'links the de-emphasized items in a muted color' do
        render_inline(toc)

        expect(unit('Bonus')).to have_link('Bonus', visible: :all)
        expect(unit('Bonus').find('a', visible: :all)[:class].split)
          .to include('text-base-content/60')
        expect(unit('Video').find('a', visible: :all)[:class].split)
          .to include('text-base-content')
      end
    end

    context 'for a user without enrollment' do
      it 'only links the previewable videos' do
        render_inline(toc)

        expect(unit('Video')).to have_link('Video', visible: :all)
        expect(unit('Quiz')).to have_no_link(visible: :all)
        expect(unit('Upcoming')).to have_no_link(visible: :all)
      end
    end

    context 'for a user with access to all content' do
      before do
        allow(user).to receive(:allowed?).with('course.content.access').and_return(true)
      end

      it 'links all items' do
        render_inline(toc)

        expect(unit('Upcoming')).to have_link('Upcoming', visible: :all)
        expect(unit('Quiz')).to have_link('Quiz', visible: :all)
      end

      it 'shows the items outside their dates as locked' do
        render_inline(toc)

        upcoming = unit('Upcoming').find('a', visible: :all)
        expect(upcoming[:class].split).to include('text-base-content/60')
        expect(upcoming[:class].split).not_to include('cursor-not-allowed')
        expect(unit('Quiz').find('a', visible: :all)[:class].split).to include('text-base-content')
      end
    end

    context 'in a course with a content tree' do
      let(:course) { create(:'course_service/course', :active, :with_content_tree, course_code: 'the-course') }
      let(:account_user) { create(:'account_service/user') }
      let(:user) { instance_double(CurrentUser::User, allowed?: false, logged_in?: true, id: account_user.id) }

      def unit_titles
        page.all(:xpath, "//li/*/span[contains(@class, 'line-clamp-2')]", visible: :all).map { it.text(:all) }
      end

      it 'orders the items as in the content tree, not by their positions' do
        CourseService::Item.find_by!(title: 'Bonus').node
          .move_to_left_of(CourseService::Item.find_by!(title: 'Video').node)

        course.node.reload
        render_inline(toc)

        expect(unit_titles).to eq %w[Bonus Video Upcoming Quiz]
      end

      context 'with a content test' do
        let(:fork) { create(:'course_service/fork', section: other_section, course:) }

        before do
          create(:'course_service/item', section: other_section, title: 'Branch A', published: true)
            .node.move_to_child_of(fork.branches[0].node)
          create(:'course_service/item', section: other_section, title: 'Branch B', published: true)
            .node.move_to_child_of(fork.branches[1].node)
          course.node.reload
        end

        it "only shows the items of the user's content test branch" do
          AccountService::Membership.create!(user_id: user.id, group_id: fork.branches[1].group_id)

          render_inline(toc)

          expect(unit_titles).to eq ['Video', 'Upcoming', 'Bonus', 'Quiz', 'Branch B']
        end

        context 'for a user with access to all content' do
          before do
            allow(user).to receive(:allowed?).with('course.content.access').and_return(true)
          end

          it 'shows the items of all branches without assigning the user to a branch' do
            render_inline(toc)

            expect(unit_titles).to eq ['Video', 'Upcoming', 'Bonus', 'Quiz', 'Branch A', 'Branch B']
            expect(AccountService::Membership.where(user_id: user.id)).to be_empty
          end
        end
      end
    end

    context "with the user's progress" do
      let(:account_user) { create(:'account_service/user') }
      let(:user) { instance_double(CurrentUser::User, allowed?: false, logged_in?: true, id: account_user.id) }

      before do
        allow(user).to receive(:allowed?).with('course.content.access.available').and_return(true)

        create(:'course_service/visit', user: account_user, item: CourseService::Item.find_by!(title: 'Video'))
        create(:'course_service/item', section: other_section, title: 'Low score quiz', content_type: 'quiz',
          exercise_type: 'main', max_dpoints: 100, published: true).tap do |quiz|
          create(:'course_service/result', user: account_user, item: quiz, dpoints: 30)
        end
        create(:'course_service/item', section: other_section, title: 'Sufficient score quiz', content_type: 'quiz',
          exercise_type: 'main', max_dpoints: 100, published: true).tap do |quiz|
          create(:'course_service/result', user: account_user, item: quiz, dpoints: 60)
        end
      end

      it 'marks the items with content completed or a sufficient score' do
        render_inline(toc)

        expect(unit('Video')).to have_css('.sr-only', exact_text: 'Completed', visible: :all)
        expect(unit('Sufficient score quiz')).to have_css('.sr-only', exact_text: 'Completed', visible: :all)
        expect(unit('Low score quiz')).to have_no_css('.sr-only', exact_text: 'Completed', visible: :all)
        expect(unit('Quiz')).to have_no_css('.sr-only', exact_text: 'Completed', visible: :all)
        expect(unit('Upcoming')).to have_no_css('.sr-only', exact_text: 'Completed', visible: :all)
      end

      it 'shows the number of completed items per section' do
        render_inline(toc)

        expect(page.find('summary', text: 'Week 1')).to have_css('.sr-only', exact_text: '1 of 3 completed')
        expect(page.find('summary', text: 'Week 2')).to have_css('.sr-only', exact_text: '1 of 3 completed')
      end

      context 'as an anonymous user' do
        let(:user) { instance_double(CurrentUser::AnonymousUser, allowed?: false, logged_in?: false) }

        it 'marks no items and shows no section progress' do
          render_inline(toc)

          expect(page).to have_no_text(:all, /completed/i)
        end
      end
    end
  end
end
