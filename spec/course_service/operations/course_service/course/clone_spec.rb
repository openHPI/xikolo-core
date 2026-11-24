# frozen_string_literal: true

require 'spec_helper'

describe CourseService::Course::Clone do
  let(:course) do
    create(:'course_service/course', :full_blown, course_code: 'original-course', records_released: true)
  end
  let(:context_id) { AccountService::Context.root.id }

  before do
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
      .to_return Stub.json({clone_url: '/quiz_service/quizzes/00000000-3333-4444-9999-000000000001/clone'})
    Stub.request(:quiz, :post, '/quizzes/00000000-3333-4444-9999-000000000001/clone')
      .to_return Stub.json({id: '00000000-3333-4444-9999-000000000103'})
  end

  describe 'clone into fresh course' do
    subject(:new_course) do
      described_class.call(course.id, 'cloned-course')
      CourseService::Course.find_by course_code: 'cloned-course'
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
          :put, %r{#{test_s3_host}/xikolo-public/courses/[a-zA-Z0-9]+/rtfiles/34/logo.jpg}
        ).and_return(status: 200, body: '<xml></xml>')

        expect(new_course.description).not_to eq course.description
        expect(new_course.description).to start_with("Test\ns3://xikolo-public/courses/")
        expect(copy_file).to have_been_requested
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
            :put, %r{#{test_s3_host}/xikolo-public/courses/[a-zA-Z0-9]+/[a-zA-Z0-9]+/course_visual.png}
          ).and_return(status: 200, body: '<xml></xml>')
        end

        context 'with only images' do
          before do
            create(:visual, course_id: course.id)
          end

          it 'clones the course visual' do
            expect { new_course }.to change(Course::Visual, :count).from(1).to(2)
          end

          it 'requests to copy the file of the image on s3' do
            new_course
            expect(copy_visual).to have_been_requested
          end

          it 'creates a new uri for the copied image on s3' do
            expect(new_course.visual.image_uri).not_to eq course.visual.image_uri
            expect(new_course.visual.image_uri).to match(%r{s3://xikolo-public/courses/#{new_course_id_encoded}/[a-zA-Z0-9]+/course_visual.png})
          end
        end

        context 'with a teaser video' do
          before do
            create(:visual, :with_video, course_id: course.id)
          end

          it 'clones the teaser video' do
            # CourseService::The teaser video and a video item from a section are getting cloned
            expect { new_course }.to change(Video::Video, :count).from(2).to(4)
            expect(new_course.visual.video).to be_persisted
          end
        end
      end

      context 'with invalid course visuals' do
        let!(:copy_visual) do
          stub_request(
            :put, %r{#{test_s3_host}/xikolo-public/courses/[a-zA-Z0-9]+/[a-zA-Z0-9]+/course_visual.png}
          ).and_return(status: 404)
        end

        before do
          create(:visual, course_id: course.id)
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
        item = new_course.items.find {|i| i.content_type == 'CourseService::Richtext' }
        orig_item = course.items.find {|i| i.content_type == 'CourseService::Richtext' }
        expect(item.original_item_id).to eq orig_item.id
      end

      it 'has a cloned video item' do
        items = new_course.items
        expect(items.count {|i| i.content_type == 'Video::Video' }).to eq 1
        orig_items = course.items
        expect(items.find {|i| i.content_type == 'Video::Video' }.id).not_to eq orig_items.find {|i| i.content_type == 'Video::Video' }.id
      end

      it 'has a cloned text item' do
        items = new_course.items.select {|i| i.content_type == 'CourseService::Richtext' }
        expect(items.count).to eq 1
        orig_items = course.items
        expect(items.first.id).not_to eq orig_items.find {|i| i.content_type == 'CourseService::Richtext' }.id
        expect(CourseService::Richtext.find(items.first.content_id)).to be_persisted
      end

      it 'copies referenced files for text items' do
        course.items.where(content_type: 'CourseService::Richtext').find_each do |item|
          item.delete
          CourseService::Richtext.destroy item.content_id
        end
        rts = create_list(:'course_service/richtext', 2, course_id: course.id, text: "Test\ns3://xikolo-public/courses/oldId/rtfiles/34/logo.jpg")
        rts.each do |richtext|
          create(:'course_service/item', section: course.sections.first, content: richtext)
        end

        copy_file = stub_request(
          :put, %r{#{test_s3_host}/xikolo-public/courses/[a-zA-Z0-9]+/rtfiles/34/logo.jpg}
        ).and_return(status: 200, body: '<xml></xml>')

        new_items = new_course.items.where(content_type: 'CourseService::Richtext')
        expect(new_items.count).to eq 2
        new_rts = new_items.map {|item| CourseService::Richtext.find item.content_id }
        expect(new_rts.first.text.to_s).to eq new_rts.second.text.to_s
        expect(copy_file).to have_been_requested
        rts.zip(new_rts).each do |old_rt, new_rt|
          expect(new_rt.course_id).to eq new_course.id
          expect(new_rt.text.to_s).not_to eq old_rt.text.to_s
        end
      end

      it 'copies the attached reading material for text items' do
        original_uri = 's3://xikolo-public/courses/oldId/rtfiles/ab12/reading_material.pdf'
        richtext = create(:'course_service/richtext', course_id: course.id, reading_material_uri: original_uri)
        item = create(:'course_service/item', section: course.sections.first, content: richtext)

        copy_stub = stub_request(
          :put, %r{#{test_s3_host}/xikolo-public/courses/[a-zA-Z0-9]+/rtfiles/[a-zA-Z0-9]+/reading_material.pdf}
        ).and_return(status: 200, body: '<xml></xml>')

        new_course

        copied_item = new_course.items.find_by!(original_item_id: item.id)
        copied_rt = CourseService::Richtext.find copied_item.content_id

        expect(copy_stub).to have_been_requested
        expect(copied_rt.reading_material_uri).to match(
          %r{\As3://xikolo-public/courses/#{UUID4(new_course.id).to_str(format: :base62)}/rtfiles/[a-zA-Z0-9]+/reading_material\.pdf\z}
        )
      end

      context 'with an LTI exercise' do
        let(:lti_exercise) { create(:lti_exercise, provider: lti_provider) }
        let(:lti_provider) { create(:lti_provider) }

        before do
          create(:'course_service/item',
            section: course.sections.first,
            title: 'LTI Exercise',
            exercise_type: 'selftest',
            content: lti_exercise)
        end

        it 'calls the CourseService::LTI exercise clone operation' do
          expect(CourseService::LtiExercise::Clone).to receive(:call).once
          new_course
        end

        it 'creates a new LTI exercise item' do
          original_items = course.items
          new_items = new_course.items

          expect(original_items.count {|i| i.content_type == 'Lti::Exercise' }).to eq 1
          expect(new_items.count {|i| i.content_type == 'Lti::Exercise' }).to eq 1
          expect(new_items.find {|i| i.content_type == 'Lti::Exercise' }.id)
            .not_to eq original_items.find {|i| i.content_type == 'Lti::Exercise' }.id
        end

        it 'creates a new CourseService::LTI provider' do
          new_provider = Lti::Provider.where(course_id: new_course.id)
          expect(new_provider.count).to eq 1
        end

        context 'with a global provider' do
          let(:lti_provider) { create(:lti_provider, :global) }

          it 'does not copy the provider' do
            expect { new_course }.not_to change(Lti::Provider, :count)
            expect(Lti::Provider.where(course_id: new_course.id).count).to be_zero
          end
        end
      end

      it 'has a cloned quiz item' do
        items = new_course.items
        orig_items = course.items
        expect(items.count {|i| i.content_type == 'QuizService::Quiz' }).to eq 1
        expect(items.find {|i| i.content_type == 'QuizService::Quiz' }.id).not_to eq orig_items.find {|i| i.content_type == 'QuizService::Quiz' }.id
      end

      context 'with a quiz with a submission deadline' do
        before do
          item = course.items.where(content_type: 'QuizService::Quiz').first
          item.update!(submission_deadline: 1.week.ago)
        end

        it 'resets the submission deadline' do
          expect(new_course.items).to all have_attributes(submission_deadline: nil)
        end
      end
    end
  end

  describe 'clone into existing course' do
    subject(:existing_course) do
      described_class.call(course.id, 'existing-course')
      CourseService::Course.find_by course_code: 'existing-course'
    end

    before { create(:'course_service/course', course_code: 'existing-course', created_at: 2.months.ago) }

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
