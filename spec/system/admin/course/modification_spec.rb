# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Modify Course', type: :system do
  let(:teacher_1) { create(:'course_service/teacher') }
  let(:teacher_2) { create(:'course_service/teacher') }
  let(:teacher_3) { create(:'course_service/teacher') }
  let(:user) {  create(:'account_service/user', :gdpr_admin) }
  let!(:course) { create(:course, :with_teaser_video, video:, course_code: 'my-course', title: 'In-Memory Data Management-Entwicklung - Iteration', description: 'This is the Automated Testing (2018 Edition).') }
  let(:course_resource) { build(:'course:course', course_params) }
  let(:course_params) do
    {
      id: course.id,
      course_code: course.course_code,
      title: course.title,
      description: course.description,
    }
  end
  let(:video) { create(:video, pip_stream: stream) }
  let(:stream) { create(:stream, title: 'The stream', provider:) }
  let(:provider) { create(:video_provider, :vimeo, name: 'The provider') }

  before do
    sign_in(user:)
  end

  describe 'editing course properties' do
    it 'does not remove the teaser video when editing other course properties' do
      course_teaser = course.visual.video_stream_id

      visit '/learn/my-course/edit'
      expect(page).to have_text 'The stream (The provider)'

      # Add a teacher
      tom_select teacher_1.name, from: 'Teachers'

      click_on 'Update course'

      expect(page).to have_text 'The course has been updated.'
      expect(course.reload.teacher_ids).to eq([teacher_1.id])

      # The course teaser video was not removed
      expect(course.reload.visual.video_stream_id).to eq course_teaser
    end

    context 'when selecting a classifier' do
      let(:topic) { create(:cluster, :visible, id: 'topic', translations: {en: 'Topics', de: 'Themen'}) }

      before do
        create(:classifier, cluster: topic, title: 'programming', translations: {en: 'Programming', de: 'Programmierung'})
        create(:classifier, cluster: topic, title: 'databases', translations: {en: 'Databases', de: 'Datenbanken'})
      end

      it "lets the user select any of the platform's visible classifiers" do
        visit '/learn/my-course/edit'
        find(:label, text: 'Topics').click

        expect(page).to have_text 'Programming'
        expect(page).to have_text 'Databases'
      end

      it "shows the best translation depending on the platform's language" do
        visit '/learn/my-course/edit'
        find('button[aria-description="Choose Language"]').click
        click_on 'Deutsch'
        find(:label, text: 'Themen').click

        expect(page).to have_text 'Programmierung'
        expect(page).to have_text 'Datenbanken'
        expect(page).to have_no_text 'Programming'
        expect(page).to have_no_text 'Databases'
      end
    end
  end
end
