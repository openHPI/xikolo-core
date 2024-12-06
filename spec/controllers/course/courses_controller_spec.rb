# frozen_string_literal: true

require 'spec_helper'
require 'rspec/expectations'

describe Course::CoursesController, type: :controller do
  let(:user_id) { '00000001-3100-4444-9999-000000000001' }
  let(:course) { create(:course, :with_visual, course_code: 'test') }
  let(:section_id) { generate(:section_id) }
  let(:forward_item_id) { generate(:item_id) }
  let(:teacher_id) { '00000001-3100-4444-9999-000000000002' }
  let(:enrollment) { [] }

  before do
    Stub.service(:account, session_url: '/sessions/{id}')
    Stub.service(:course, build(:'course:root'))
    Stub.request(
      :course, :get, '/next_dates',
      query: hash_including({})
    ).to_return Stub.json([])
  end

  describe '#resume' do
    subject(:resume) { request; response }

    let(:request) { get :resume, params: {id: course.course_code} }
    let(:request_context_id) { course_context_id }

    before do
      Stub.request(
        :course, :get, "/courses/#{course.course_code}"
      ).to_return Stub.json({
        id: course.id,
        course_code: course.course_code,
        status: 'active',
        context_id: course_context_id,
      })

      Stub.request(
        :course, :get, '/enrollments',
        query: {course_id: course.id, user_id:}
      ).to_return Stub.json(enrollment)
    end

    context 'as anonymous' do
      context 'without any available item' do
        before do
          Stub.request(
            :course, :get, '/items/current',
            query: {course: course.id, user: 'anonymous', preview: 'false'}
          ).to_return Stub.response(status: 404)
        end

        its(:status) { is_expected.to eq 302 }

        it 'redirects to the course details page' do
          expect(resume).to redirect_to course_path course.course_code
        end

        it 'displays a flash notice' do
          request
          expect(flash[:notice]).to include 'There is no public course content yet.'
        end
      end

      context 'with current item' do
        before do
          Stub.request(
            :course, :get, '/items/current',
            query: {course: course.id, user: 'anonymous', preview: 'false'}
          ).to_return Stub.json({id: forward_item_id})
        end

        its(:status) { is_expected.to eq 302 }

        it 'redirects to the current item' do
          expect(resume).to redirect_to course_item_path(
            course.course_code,
            short_uuid(forward_item_id)
          )
        end
      end
    end

    context 'as an enrolled user' do
      let(:enrollment) { create(:enrollment, user_id:, course:) }

      before do
        stub_user id: user_id, language: 'en', permissions: ['course.content.access.available']
      end

      context 'without any available item' do
        before do
          Stub.request(
            :course, :get, '/items/current',
            query: {course: course.id, user: user_id, preview: 'false'}
          ).to_return Stub.response(status: 404)
        end

        its(:status) { is_expected.to eq 302 }

        it 'redirects to the course details page' do
          expect(resume).to redirect_to course_path course.course_code
        end

        it 'displays a flash notice' do
          request
          expect(flash[:notice]).to include 'There is no public course content yet.'
        end
      end

      context 'with current item' do
        before do
          Stub.request(
            :course, :get, '/items/current',
            query: {course: course.id, user: user_id, preview: 'false'}
          ).to_return Stub.json({id: forward_item_id})
        end

        its(:status) { is_expected.to eq 302 }

        it 'redirects to the current item' do
          expect(resume).to redirect_to course_item_path(
            course.course_code,
            short_uuid(forward_item_id)
          )
        end
      end
    end

    context 'as a not enrolled user' do
      before do
        stub_user id: user_id, language: 'en', permissions: []
      end

      context 'without any available item' do
        before do
          Stub.request(
            :course, :get, '/items/current',
            query: {course: course.id, user: user_id, preview: 'false'}
          ).to_return Stub.response(status: 404)
        end

        its(:status) { is_expected.to eq 302 }

        it 'redirects to the course details page' do
          expect(resume).to redirect_to course_path course.course_code
        end

        it 'displays a flash notice' do
          request
          expect(flash[:notice]).to include 'There is no public course content yet.'
        end
      end

      context 'with current item' do
        before do
          Stub.request(
            :course, :get, '/items/current',
            query: {course: course.id, user: user_id, preview: 'false'}
          ).to_return Stub.json({id: forward_item_id})
        end

        its(:status) { is_expected.to eq 302 }

        it 'redirects to the current item' do
          expect(resume).to redirect_to course_item_path(
            course.course_code,
            short_uuid(forward_item_id)
          )
        end
      end
    end
  end

  describe '#show' do
    let(:request_context_id) { course_context_id }

    before do
      Stub.request(
        :course, :get, '/items',
        query: {course_id: course.id, featured: true, content_type: 'video'}
      ).to_return Stub.json([])
    end

    context 'for course in preparation' do
      subject(:request) { get :show, params: {id: course.id} }

      before do
        Stub.request(
          :course, :get, "/courses/#{course.id}"
        ).to_return Stub.json({
          id: course.id,
          status: 'preparation',
          context_id: course_context_id,
        })
      end

      context 'as anonymous user' do
        it 'cannot access the course' do
          expect { request }.to raise_error Status::NotFound
        end
      end

      context 'as logged in user' do
        before { stub_user id: '99c29e4b-28e0-42e4-b46f-7f289edb8c3a' }

        it 'cannot access the course' do
          expect { request }.to raise_error Status::NotFound
        end
      end
    end

    context 'for active course' do
      subject { get_request; response }

      let(:get_request) { get :show, params: {id: course.course_code} }
      let(:abstract) { 'Abstract' }
      let(:now) { DateTime.current }
      let(:classifiers) { nil }
      let(:hidden) { false }

      before do
        Stub.request(
          :course, :get, "/courses/#{course.course_code}"
        ).to_return Stub.json({
          id: course.id,
          status: 'active',
          teacher_ids: [teacher_id],
          description: 'Description',
          abstract:,
          title: 'Title',
          course_code: course.course_code,
          lang: 'en',
          context_id: course_context_id,
          teacher_text: 'Teachers!',
          created_at: now - 2.weeks,
          updated_at: now - 1.week,
          classifiers:,
          hidden:,
        })

        Stub.request(
          :course, :get, '/sections',
          query: {course_id: course.id}
        ).to_return Stub.json([
          {id: section_id, position: 1},
        ])

        Stub.request(
          :course, :get, '/stats',
          query: hash_including(course_id: course.id, key: 'enrollments')
        ).to_return Stub.json({enrollments: 9999})

        Stub.request(
          :course, :get, '/teachers',
          query: {course: course.id}
        ).to_return Stub.json([
          {id: teacher_id, name: 'John Doe'},
        ])
      end

      context 'as anonymous user' do
        it { is_expected.to redirect_to dashboard_path }
      end

      context 'for logged-in users' do
        context 'w/o permission to access the course details' do
          before { stub_user id: user_id }

          it { is_expected.to redirect_to dashboard_path }
        end

        context 'w/ permission to see the course details' do
          before { stub_user id: user_id, permissions: %w[course.course.show] }

          it 'answers with a page' do
            expect(get_request.status).to eq 200
          end
        end
      end

      context 'for meta tags' do
        render_views

        subject(:course_details) { get_request; response.body }

        let(:get_request) { get :show, params: {id: course.course_code} }
        let(:anonymous_session) { super().merge(permissions: %w[course.course.show]) }

        it 'has the correct title meta tag' do
          expect(course_details).to _have_xpath('html/head/title', text: 'Title | Xikolo')
        end

        it 'has the correct description' do
          expect(course_details).to _have_xpath("html/head/meta[@name='description']", content: 'Abstract')
        end

        it 'has no robots tag' do
          expect(course_details).not_to _have_xpath("html/head/meta[@name='robots']", content: 'noindex')
        end

        context 'without abstract' do
          let(:abstract) { nil }

          it 'has the correct description (falling back to course description)' do
            expect(course_details).to _have_xpath("html/head/meta[@name='description']", content: 'Description')
          end
        end

        it 'has the correct timestamps' do
          expect(course_details).to _have_xpath("html/head/meta[@name='dcterms.created']", content: (now - 2.weeks).to_s)
          expect(course_details).to _have_xpath("html/head/meta[@name='dcterms.modified']", content: (now - 1.week).to_s)
        end

        it 'has no keywords' do
          expect(course_details).not_to _have_xpath("html/head/meta[@name='keywords']")
        end

        context 'with keyword classifiers' do
          let(:classifiers) { {keywords: %w[p3k i18n]} }

          it 'has the correct keywords' do
            expect(course_details).to _have_xpath("html/head/meta[@name='keywords']", content: 'p3k, i18n')
          end

          context 'with additional topic classifier' do
            let(:classifiers) { super().merge(topic: ['topic']) }

            it 'has the correct keywords' do
              expect(course_details).to _have_xpath("html/head/meta[@name='keywords']", content: 'p3k, i18n, topic')
            end
          end
        end

        context 'with facebook app id' do
          before do
            xi_config <<~YML
              facebook_app_id: fb_app_id
            YML
          end

          it 'includes the facebook app id' do
            expect(course_details).to _have_xpath("html/head/meta[@property='fb:app_id']", content: 'fb_app_id')
          end
        end

        it 'has the correct OpenGraph meta tags' do
          expect(course_details).to _have_xpath("html/head/meta[@property='og:title']", content: 'Title')
          expect(course_details).to _have_xpath("html/head/meta[@property='og:image']", content: 'https://s3.xikolo.de/xikolo-public/courses/123/456/course_visual.png')
          expect(course_details).to _have_xpath("html/head/meta[@property='og:type']", content: 'website')
          expect(course_details).to _have_xpath("html/head/meta[@property='og:url']", content: 'https://xikolo.de/courses/test')
          expect(course_details).to _have_xpath("html/head/meta[@property='og:description']", content: 'Abstract')
          expect(course_details).to _have_xpath("html/head/meta[@property='og:site_name']", content: 'Xikolo')
          expect(course_details).to _have_xpath("html/head/meta[@property='og:image:secure_url']", content: 'https://s3.xikolo.de/xikolo-public/courses/123/456/course_visual.png')
          expect(course_details).to _have_xpath("html/head/meta[@property='og:locale']", content: 'en')
        end

        context 'for hidden courses' do
          let(:hidden) { true }

          it 'has noindex in the robots tag' do
            expect(course_details).to _have_xpath("html/head/meta[@name='robots']", content: 'noindex')
          end
        end
      end
    end

    context 'for miss-cased course code' do
      subject(:response) { get :show, params: {id: 'TEST'} }

      before do
        Stub.request(
          :course, :get, '/courses/TEST'
        ).to_return Stub.json({
          id: course.id,
          course_code: 'test',
          status: 'active',
          context_id: course_context_id,
        })
      end

      it 'redirects to the canonical course URL' do
        expect(response).to have_http_status :moved_permanently
        expect(response).to redirect_to course_url('test')
      end
    end
  end
end
