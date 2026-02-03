# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Modify Course', type: :system do
  let(:teachers) { build_list(:'course:teacher', 3) }
  let(:user_id) { user['id'] }
  let(:user) { build(:'account:user') }
  let!(:course) { create(:course, :with_teaser_video, video:, course_code: 'my-course') }
  let(:course_resource) { build(:'course:course', course_params) }
  let(:course_params) do
    {
      id: course.id,
      course_code: course.course_code,
      title: 'In-Memory Data Management-Entwicklung - Iteration',
      description: 'This is the Automated Testing (2018 Edition).',
    }
  end
  let(:video) { create(:video, pip_stream: stream) }
  let(:stream) { create(:stream, title: 'The stream', provider:) }
  let(:provider) { create(:video_provider, :vimeo, name: 'The provider') }

  before do
    stub_user id: user_id, permissions: %w[course.course.edit course.course.show course.teacher.view course.content.access]
    Stub.request(:account, :get, "/users/#{user_id}")
      .to_return Stub.json(user)
    Stub.request(:account, :get, "/users/#{user_id}/preferences")
      .to_return Stub.json({id: user_id, properties: {}})
    Stub.request(:course, :get, '/channels', query: {per_page: 250})
      .and_return(Stub.json(build_list(:'course:channel', 3)))
    Stub.request(:course, :get, '/teachers', query: hash_including({}))
      .and_return(Stub.json(teachers))
    Stub.request(:course, :get, '/courses/my-course')
      .and_return Stub.json(course_resource)
    Stub.request(:course, :get, '/courses/my-course?raw=true')
      .and_return Stub.json(course_resource)
    Stub.request(:course, :get, '/sections', query: {course_id: course.id})
      .to_return(Stub.json([]))
    Stub.request(:course, :get, '/items', query: hash_including(course_id: course.id, featured: 'true'))
      .to_return(Stub.json([]))
    Stub.request(:course, :get, "/stats?course_id=#{course.id}&key=enrollments")
      .to_return Stub.json({})
    Stub.request(:course, :get, "/stats?course_id=#{course.id}&key=percentile_created_at_days")
      .and_return Stub.json({percentile_created_at_days: {}, quantile_count: 0})
    Stub.request(:course, :get, '/next_dates', query: hash_including({}))
      .to_return Stub.json([])
    Stub.request(:course, :get, "/enrollments?course_id=#{course.id}&user_id=#{user_id}")
      .and_return Stub.json([])
  end

  describe '(error handling)' do
    let(:course_params) { super().merge(learning_goals: %w[rspec capybara], teacher_ids: [teachers.second['id']]) }

    before do
      Stub.request(:course, :get, "/teachers/#{teachers.first['id']}")
        .and_return(Stub.json(teachers.first))
      Stub.request(:course, :get, "/teachers/#{teachers.second['id']}")
        .and_return(Stub.json(teachers.second))

      Stub.request(:course, :patch, "/courses/#{course.id}")
        .to_return Stub.json({
          'errors' => {'title' => ['upload_error', 'Custom Error message']},
        }, status: 422)
    end

    it 'prefills the form and re-renders on unprocessable course data' do
      visit '/courses/my-course/edit'

      expect(page).to have_field 'Title', with: 'In-Memory Data Management-Entwicklung - Iteration'
      expect(page).to have_select 'Content language', selected: 'English'
      expect(page).to have_markdown_editor 'Description', with: 'This is the Automated Testing (2018 Edition).'

      all(:button, 'Advanced settings').map(&:click)

      tom_select teachers.first['name'], from: 'Teachers'

      fill_in('Learning goals', with: 'gurke').send_keys(:return)

      fill_in 'Policy URL (in English)', with: 'https://xikolo.de/test2018/policies.en.html'
      fill_in 'Policy URL (in German)', with: 'https://xikolo.de/test2018/policies.de.html'

      click_on 'Update course'

      expect(page).to have_content 'The course was not updated.'
      expect(page).to have_content 'Custom Error message'
      expect(page).to have_content 'Your file upload could not be stored.'

      expect(page).to have_field('Policy URL (in English)', with: 'https://xikolo.de/test2018/policies.en.html')
      expect(page).to have_field('Policy URL (in German)', with: 'https://xikolo.de/test2018/policies.de.html')
      expect(page.find('.course_learning_goals')).to have_content('gurke')
      expect(page.find('.course_teacher_ids')).to have_content(teachers.first['name'])
    end
  end

  describe 'editing course properties' do
    it 'does not remove the teaser video when editing other course properties' do
      course_teaser = course.visual.video_stream_id

      visit '/courses/my-course/edit'
      expect(page).to have_content 'The stream (The provider)'

      # Add a teacher
      tom_select teachers.first['name'], from: 'Teachers'

      update_course = Stub.request(:course, :patch, "/courses/#{course.id}")
        .to_return(status: 201)

      click_on 'Update course'

      expect(page).to have_content 'The course has been updated.'
      expect(
        update_course.with(
          body: hash_including(
            'teacher_ids' => array_including(teachers.first['id'])
          )
        )
      ).to have_been_requested

      # The course teaser video was not removed
      expect(course.reload.visual.video_stream_id).to eq course_teaser
    end

    context 'when selecting a classifier' do
      let(:topic) { create(:cluster, :visible, id: 'topic', translations: {en: 'Topics', de: 'Themen'}) }

      before do
        create(:classifier, cluster: topic, title: 'programming', translations: {en: 'Programming', de: 'Programmierung'})
        create(:classifier, cluster: topic, title: 'databases', translations: {en: 'Databases', de: 'Datenbanken'})

        Stub.request(:account, :patch, "/users/#{user_id}")
          .to_return Stub.json({
            body: hash_including({language: 'de'}),
          }, status: 200)
      end

      it "lets the user select any of the platform's visible classifiers" do
        visit '/courses/my-course/edit'
        find(:label, text: 'Topics').click

        expect(page).to have_content 'Programming'
        expect(page).to have_content 'Databases'
      end

      it "shows the best translation depending on the platform's language" do
        visit '/courses/my-course/edit'
        find('button[aria-description="Choose Language"]').click
        click_on 'Deutsch'
        find(:label, text: 'Themen').click

        expect(page).to have_content 'Programmierung'
        expect(page).to have_content 'Datenbanken'
        expect(page).to have_no_content 'Programming'
        expect(page).to have_no_content 'Databases'
      end
    end
  end
end
