# frozen_string_literal: true

module Steps
  module CourseVisual
    Given 'I am on the course visuals edit page' do
      context.with :course do |course|
        visit "/courses/#{course['course_code']}/visual/edit"
      end
    end

    When 'I attach a course visual' do
      attach_file 'Image', asset_path('redsandsforts.jpg')
    end

    When 'I submit the course visual' do
      click_on 'Save and show course'
    end

    When 'I select a stream' do
      tom_select '_internetworking_intro_pip', from: 'Teaser video', search: true
    end

    Then 'I see the visual' do
      expect(page).to have_xpath "//img[contains(@src, '/redsandsforts.jpg')]"
    end
  end
end

Gurke.configure do |c|
  c.include Steps::CourseVisual
end
