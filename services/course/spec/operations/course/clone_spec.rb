# frozen_string_literal: true

require 'spec_helper'

describe Course::Clone do
  let(:course) do
    create(:course, :full_blown, course_code: 'original-course', records_released: true)
  end
  let(:context_id) { generate(:context_id) }

  before do
    Stub.service(:account, build(:'account:root'))
    Stub.service(:quiz, build(:'quiz:root'))

    course_groups = %w[students admins moderators teachers]
    %w[original-course cloned-course].each do |course|
      Stub.request(
        :account, :post, '/contexts',
        body: {
          parent: 'root',
          reference_uri: "urn:x-xikolo:course:course:#{course}",
        }
      ).to_return Stub.json({id: context_id})

      course_groups.each do |group|
        desc = group.capitalize
        desc = 'Course Admins' if group == 'admins'
        Stub.request(
          :account, :post, '/groups',
          body: {
            name: "course.#{course}.#{group}",
            description: "#{desc} of course #{course}",
          }
        ).to_return Stub.json({name: group})
      end
    end

    Xikolo.config.course_groups.each do |group, data|
      data['grants'].each do |grant|
        Stub.request(
          :account, :post, '/grants',
          body: {
            group:,
            context: grant['context'] == 'course' ? context_id : 'root',
            role: grant['role'],
          }
        )
      end
    end

    # Stub quiz resource
    Stub.request(:quiz, :get, '/quizzes/00000000-3333-4444-9999-000000000001')
      .to_return Stub.json({clone_url: '/quizzes/00000000-3333-4444-9999-000000000001/clone'})
    Stub.request(:quiz, :post, '/quizzes/00000000-3333-4444-9999-000000000001/clone')
      .to_return Stub.json({id: '00000000-3333-4444-9999-000000000103'})
  end

  describe 'clone into fresh course' do
    subject(:new_course) do
      described_class.call(course.id, 'cloned-course')
      Course.find_by course_code: 'cloned-course'
    end

    let(:course_id_encoded) { UUID4(course.id).to_s(format: :base62) }
    let(:new_course_id_encoded) { UUID4(new_course.id).to_s(format: :base62) }

    describe '(attributes)' do
      it 'does not clone course timestamps' do
        course.update!(created_at: 1.year.ago, updated_at: 1.month.ago)

        expect(new_course).to have_attributes(
          'created_at' => be_within(1.minute).of(Time.current),
          'updated_at' => be_within(1.minute).of(Time.current)
        )
      end

      it 'resets the certificate release status' do
        expect(new_course.records_released).to be_falsey
      end

      it 'clones referenced files in the course description' do
        course.update!(description: "Test\ns3://xikolo-public/courses/oldId/rtfiles/34/logo.jpg")

        copy_file = stub_request(
          :put, %r{https://s3.xikolo.de/xikolo-public/courses/[a-zA-Z0-9]+/rtfiles/34/logo.jpg}
        ).and_return(status: 200, body: '<xml></xml>')

        expect(new_course.description).not_to eq course.description
        expect(new_course.description).to start_with("Test\ns3://xikolo-public/courses/")
        expect(copy_file).to have_been_requested
      end

      context 'when the original course is proctored' do
        let(:course) { create(:course, proctored: true) }

        it 'disables proctoring for the new course' do
          expect(new_course.proctored).to be_falsey
        end
      end

      context 'with a valid stage visual image' do
        let!(:copy_stage_visual) do
          stub_request(
            :put, %r{https://s3.xikolo.de/xikolo-public/courses/[a-zA-Z0-9]+/[a-zA-Z0-9-]+/stage_visual.jpg}
          ).and_return(status: 200, body: '<xml></xml>')
        end

        before do
          course.update!(stage_visual_uri: "s3://xikolo-public/courses/#{course_id_encoded}/encodedUUUID/stage_visual.jpg")
        end

        it 'requests to copy the stage visual image on S3' do
          new_course
          expect(copy_stage_visual).to have_been_requested
        end

        it 'creates a new uri for the copied stage visual image on s3' do
          expect(new_course.stage_visual_uri).not_to eq course.stage_visual_uri
          expect(new_course.stage_visual_uri).to match(%r{s3://xikolo-public/courses/#{new_course_id_encoded}/encodedUUUID/stage_visual.jpg})
        end
      end

      context 'with an invalid stage visual image' do
        let!(:copy_stage_visual) do
          stub_request(
            :put, %r{https://s3.xikolo.de/xikolo-public/courses/[a-zA-Z0-9]+/[a-zA-Z0-9-]+/stage_visual.jpg}
          ).and_return(status: 404)
        end

        before do
          course.update!(stage_visual_uri: "s3://xikolo-public/courses/#{course_id_encoded}/encodedUUUID/stage_visual.jpg")
        end

        it 'does not copy the stage visual' do
          expect(new_course.stage_visual_uri).to be_nil
          expect(copy_stage_visual).to have_been_requested
        end
      end
    end

    describe 'clones associated visuals' do
      context 'without a course visual' do
        it 'does not create a new course visual' do
          expect(new_course.visual).to be_nil
        end

        it 'does not create a new teaser video' do
          expect(new_course&.visual&.video).to be_nil
        end
      end

      context 'with a valid course visual' do
        let!(:copy_visual) do
          stub_request(
            :put, %r{https://s3.xikolo.de/xikolo-public/courses/[a-zA-Z0-9]+/[a-zA-Z0-9]+/course_visual.png}
          ).and_return(status: 200, body: '<xml></xml>')
        end

        context 'with only images' do
          before do
            create(:visual, course:)
          end

          it 'clones the course visual' do
            expect { new_course }.to change(Duplicated::Visual, :count).from(1).to(2)
          end

          it 'requests to copy the file of the image on s3' do
            new_course
            expect(copy_visual).to have_been_requested
          end

          it 'creates a new uri for the copied image on s3' do
            expect(new_course.visual.image_uri).not_to eq course.visual.image_uri
            expect(new_course.visual.image_uri).to match(%r{s3://xikolo-public/courses/#{new_course_id_encoded}/encodedUUUID/course_visual.png})
          end
        end

        context 'with a teaser video' do
          before do
            create(:visual, :with_video, course:)
          end

          it 'clones the teaser video' do
            # The teaser video and a video item from a section are getting cloned
            expect { new_course }.to change(Duplicated::Video, :count).from(2).to(4)
            expect(new_course.visual.video).to be_persisted
          end
        end
      end

      context 'with invalid course visuals' do
        let!(:copy_visual) do
          stub_request(
            :put, %r{https://s3.xikolo.de/xikolo-public/courses/[a-zA-Z0-9]+/[a-zA-Z0-9]+/course_visual.png}
          ).and_return(status: 404)
        end

        before do
          create(:visual, course:)
        end

        it 'does not clone the course visual' do
          expect(new_course.visual).to be_nil
          expect(copy_visual).to have_been_requested
        end
      end
    end

    describe '(content)' do
      it 'clones all sections' do
        expect(new_course.sections.count).to eq 3
      end

      it 'clones the structure of alternative sections' do
        new_sections = new_course.sections
        new_parents = new_sections.select {|s| s.alternative_state == 'parent' }
        new_childs = new_sections.select {|s| s.alternative_state == 'child' }

        expect(new_parents.count).to eq 1
        expect(new_childs.count).to eq 2
        expect(new_childs).to all have_attributes(parent_id: new_parents.first.id)
      end

      it 'has three items' do
        expect(new_course.items.count).to eq 3
      end

      it 'stores the original item ID' do
        item = new_course.items.find {|i| i.content_type == 'rich_text' }
        orig_item = course.items.find {|i| i.content_type == 'rich_text' }
        expect(item.original_item_id).to eq orig_item.id
      end

      it 'has a cloned video item' do
        items = new_course.items
        expect(items.count {|i| i.content_type == 'video' }).to eq 1
        orig_items = course.items
        expect(items.find {|i| i.content_type == 'video' }.id).not_to eq orig_items.find {|i| i.content_type == 'video' }.id
      end

      it 'has a cloned text item' do
        items = new_course.items.select {|i| i.content_type == 'rich_text' }
        expect(items.count).to eq 1
        orig_items = course.items
        expect(items.first.id).not_to eq orig_items.find {|i| i.content_type == 'rich_text' }.id
        expect(Richtext.find(items.first.content_id)).to be_persisted
      end

      it 'copies referenced files for text items' do
        course.items.where(content_type: 'rich_text').find_each do |item|
          Richtext.destroy item.content_id
          item.delete
        end
        rts = create_list(:richtext, 2, course_id: course.id, text: "Test\ns3://xikolo-public/courses/oldId/rtfiles/34/logo.jpg")
        rts.each do |richtext|
          create(:item, section: course.sections.first, content_id: richtext.id, content_type: 'rich_text')
        end

        copy_file = stub_request(
          :put, %r{https://s3.xikolo.de/xikolo-public/courses/[a-zA-Z0-9]+/rtfiles/34/logo.jpg}
        ).and_return(status: 200, body: '<xml></xml>')

        new_items = new_course.items.where(content_type: 'rich_text')
        expect(new_items.count).to eq 2
        new_rts = new_items.map {|item| Richtext.find item.content_id }
        expect(new_rts.first.text).to eq new_rts.second.text
        expect(copy_file).to have_been_requested
        rts.zip(new_rts).each do |old_rt, new_rt|
          expect(new_rt.course_id).to eq new_course.id
          expect(new_rt.text).not_to eq old_rt.text
        end
      end

      context 'with an LTI exercise' do
        let(:lti_exercise) { create(:lti_exercise, lti_provider:) }
        let(:lti_provider) { create(:lti_provider) }

        before do
          create(:item,
            section: course.sections.first,
            title: 'LTI Exercise',
            content_type: 'lti_exercise',
            exercise_type: 'selftest',
            content_id: lti_exercise.id)
        end

        it 'calls the LTI exercise clone operation' do
          expect(LtiExercise::Clone).to receive(:call).once
          new_course
        end

        it 'creates a new LTI exercise item' do
          original_items = course.items
          new_items = new_course.items

          expect(original_items.count {|i| i.content_type == 'lti_exercise' }).to eq 1
          expect(new_items.count {|i| i.content_type == 'lti_exercise' }).to eq 1
          expect(new_items.find {|i| i.content_type == 'lti_exercise' }.id)
            .not_to eq original_items.find {|i| i.content_type == 'lti_exercise' }.id
        end

        it 'creates a new LTI provider' do
          new_provider = Duplicated::LtiProvider.where(course_id: new_course.id)
          expect(new_provider.count).to eq 1
        end

        context 'with a global provider' do
          let(:lti_provider) { create(:lti_provider, :global) }

          it 'does not copy the provider' do
            expect { new_course }.not_to change(Duplicated::LtiProvider, :count)
            expect(Duplicated::LtiProvider.where(course_id: new_course.id).count).to be_zero
          end
        end
      end

      it 'has a cloned quiz item' do
        items = new_course.items
        orig_items = course.items
        expect(items.count {|i| i.content_type == 'quiz' }).to eq 1
        expect(items.find {|i| i.content_type == 'quiz' }.id).not_to eq orig_items.find {|i| i.content_type == 'quiz' }.id
      end

      context 'with a quiz with a submission deadline' do
        before do
          item = course.items.where(content_type: 'quiz').first
          item.update!(submission_deadline: 1.week.ago)
        end

        it 'resets the submission deadline' do
          expect(new_course.items).to all have_attributes(submission_deadline: nil)
        end
      end

      context 'with a proctored quiz' do
        before do
          item = course.items.where(content_type: 'quiz').first
          # Proctored items require a submission deadline.
          item.update!(proctored: true, submission_deadline: 1.week.ago)
        end

        it 'resets the proctored status and the submission deadline' do
          expect(new_course.items).to all have_attributes(
            proctored: false,
            submission_deadline: nil
          )
        end
      end

      it 'clones the time efforts for non-video items only' do
        # Add a time effort to the existing items
        original = course.items
        original.find {|i| i.content_type == 'video' }.update!(time_effort: 10)
        original.find {|i| i.content_type == 'rich_text' }.update!(time_effort: 20)
        original.find {|i| i.content_type == 'quiz' }.update!(time_effort: 30)

        # Clone the course items and check for the time effort
        cloned = new_course.items
        expect(cloned.find {|i| i.content_type == 'video' }.time_effort).to be_nil
        expect(cloned.find {|i| i.content_type == 'rich_text' }.time_effort).to eq 20
        expect(cloned.find {|i| i.content_type == 'quiz' }.time_effort).to eq 30
      end
    end
  end

  describe 'clone into existing course' do
    subject(:existing_course) do
      described_class.call(course.id, 'existing-course')
      Course.find_by course_code: 'existing-course'
    end

    before { create(:course, course_code: 'existing-course', created_at: 2.months.ago) }

    describe '(attributes)' do
      it 'does not overwrite course timestamps' do
        course.update!(created_at: 1.year.ago)

        expect(existing_course).to have_attributes(
          'created_at' => be_within(1.minute).of(2.months.ago)
        )
      end

      it 'resets the certificate release status' do
        expect(existing_course.records_released).to be_falsey
      end

      describe 'when the original course is proctored' do
        let(:course) { create(:course, proctored: true) }

        it 'disables proctoring for the course' do
          expect(existing_course.proctored).to be_falsey
        end
      end
    end

    describe '(content)' do
      it 'clones all sections' do
        expect(existing_course.sections.count).to eq 3
        expect(existing_course.sections.first.id).not_to eq course.sections.first.id
      end

      it 'clones all items' do
        expect(existing_course.items.count).to eq 3
      end
    end
  end
end
