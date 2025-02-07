# frozen_string_literal: true

module Steps
  module AlternativeSection
    def create_parent_section(attrs = {})
      course = context.fetch :course

      data = {
        title: 'Parent Section',
        description: 'In this section you can choose between several alternatives',
        published: true,
        course_id: course['id'],
        alternative_state: 'parent',
      }

      data.merge! attrs
      data.compact!

      Server[:course].api.rel(:sections).post(data).value!
    end

    def create_child_section(attrs = {})
      parent_section = context.fetch :parent_section
      course = context.fetch :course

      data = {
        published: true,
        parent_id: parent_section['id'],
        course_id: course['id'],
        alternative_state: 'child',
      }

      data.merge! attrs
      data.compact!

      Server[:course].api.rel(:sections).post(data).value!
    end

    def create_child_section_item(attrs = {})
      data = {
        instructions: attrs[:markup],
        time_limit_seconds: 3600,
        unlimited_time: false,
        allowed_attempts: 2,
        unlimited_attempts: false,
      }
      quiz = Server[:quiz].api.rel(:quizzes).post(data).value!

      data = {
        start_date: 14.days.ago,
        end_date: 14.days.from_now,
        show_in_nav: true,
        content_id: quiz['id'],
        content_type: 'quiz',
        max_points: 3,
        exercise_type: 'selftest',
      }
      data.merge! attrs
      data.compact!
      Server[:course].api.rel(:items).post(data).value!
    end

    Given 'alternative parent and child sections were created' do
      context.assign :parent_section, create_parent_section
      context.assign :child_section1,
        create_child_section(
          title: 'Alternative Section 1',
          description: 'This is the first alternative you can choose'
        )
      context.assign :child_section2,
        create_child_section(
          title: 'Alternative Section 2',
          description: 'This is the second alternative you can choose'
        )
    end

    Given 'items for child alternatives were created' do
      context.with :child_section1, :child_section2 do |s1, s2|
        context.assign :child_item1,
          create_child_section_item(
            section_id: s1['id'],
            title: 'Alternative Item 1',
            markup: 'This is the unique text of alternative item 1'
          )
        context.assign :child_item2,
          create_child_section_item(
            section_id: s2['id'],
            title: 'Alternative Item 2',
            markup: 'This is the unique text of alternative item 2'
          )
      end
    end

    Given 'I am on the parent section page' do
      context.with :course, :parent_section do |course, section|
        visit "/courses/#{course['course_code']}/sections/#{section['id']}"
      end
    end

    When 'I add an alternative section' do
      find('a', text: 'Add alternative section').click
    end

    When 'I fill in the alternative section information' do
      fill_in 'Title', with: 'Alternative 1'
      fill_in 'Description',
        with: 'This is the first alternative you can choose'
    end

    When 'I select the first alternative section' do
      within('div.course-area-main') do
        click_on('Select', match: :first)
      end
    end

    When 'I select the second alternative section' do
      click_on 'Parent Section'
      click_on 'Select'
    end

    Then 'I should get feedback that the alternative section was created' do
      expect(page).to have_notice 'The section Alternative 1 has been updated.'
    end

    Then 'the first alternative section should be listed' do
      context.with :child_section1 do |child_section1|
        expect(page).to have_content child_section1['title']
      end
    end

    Then 'the second alternative section should not be listed' do
      context.with :child_section2 do |child_section2|
        expect(page).to_not have_content child_section2['title']
      end
    end

    Then 'both alternative sections should be listed' do
      context.with :child_section1, :child_section2 do |s1, s2|
        expect(page).to have_content s1['title']
        expect(page).to have_content s2['title']
      end
    end

    Then 'the alternative section and its description should be listed' do
      expect(page).to have_content 'Alternative 1'
      expect(page).to have_content 'This is the first alternative you can choose'
    end

    Then 'the alternative sections and its descriptions should be listed' do
      context.with :child_section1, :child_section2 do |s1, s2|
        expect(page).to have_content s1['title']
        expect(page).to have_content s1['description']
        expect(page).to have_content s2['title']
        expect(page).to have_content s2['description']
      end
    end

    Then 'I should be on the items page of the first alternative section' do
      context.with :child_item1 do |item|
        within 'h2' do
          expect(page).to have_content item['title']
        end
      end
    end

    Then 'I should be on the items page of the second alternative section' do
      context.with :child_item2 do |item|
        within 'h2' do
          expect(page).to have_content item['title']
        end
      end
    end

    Then 'the course progress should only count one alternative section' do
      within '.course-progress' do
        expect(find('.course-progress__item', text: 'Self-test points')).to have_content('0 of 3')
        expect(find('.course-progress__item', text: 'Visited items')).to have_content('1 of 1')
      end
    end

    Then 'I should get visual feedback that the alternative section was created' do
      expect(page).to have_notice 'The section Alternative 1 has been updated.'
    end
  end
end

Gurke.configure {|c| c.include Steps::AlternativeSection }
