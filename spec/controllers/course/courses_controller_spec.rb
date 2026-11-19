# frozen_string_literal: true

require 'spec_helper'
require 'rspec/expectations'

describe Course::CoursesController, type: :controller do
  let(:user) { create(:'account_service/user') }
  let(:course) { create(:course, :with_visual, course_code: 'test') }
  let(:forward_item_id) { generate(:item_id) }
  let(:teacher_id) { '00000001-3100-4444-9999-000000000002' }
  let(:enrollment) { [] }
  let(:course_context) { AccountService::Context.root }

  describe '#resume' do
    subject(:resume) { request; response }

    let(:request) { get :resume, params: {id: course.course_code} }
    # Anonymous and non-enrolled users only ever see open-mode video items.
    let(:section) { create(:'course_service/section', course:) }

    before do
      Stub.request(
        :course, :get, "/courses/#{course.course_code}"
      ).to_return Stub.json({
        id: course.id,
        course_code: course.course_code,
        published: true,
        context_id: course_context.id,
      })

      Stub.request(
        :course, :get, '/enrollments',
        query: {course_id: course.id, user_id: user.id}
      ).to_return Stub.json(enrollment)
    end

    shared_examples 'without any available item' do
      its(:status) { is_expected.to eq 303 }

      it 'redirects to the course details page' do
        expect(resume).to redirect_to course_path course.course_code
      end

      it 'displays a flash notice' do
        request
        expect(flash[:notice]).to include 'There is no public course content yet.'
      end
    end

    context 'as anonymous' do
      before do
        session[:id] = nil
      end

      context 'without any available item' do
        it_behaves_like 'without any available item'
      end

      context 'with current item' do
        let!(:item) { create(:item, section:, open_mode: true) }

        its(:status) { is_expected.to eq 303 }

        it 'redirects to the current item' do
          expect(resume).to redirect_to course_item_path(
            course.course_code,
            short_uuid(item.id)
          )
        end
      end
    end

    context 'as an enrolled user' do
      let(:enrollment) { create(:enrollment, user_id: user.id, course:) }

      before do
        sign_in user: user, permissions: ['course.content.access.available']
      end

      context 'without any available item' do
        it_behaves_like 'without any available item'
      end

      context 'with current item' do
        let!(:item) { create(:item, section:) }

        its(:status) { is_expected.to eq 303 }

        it 'redirects to the current item' do
          expect(resume).to redirect_to course_item_path(
            course.course_code,
            short_uuid(item.id)
          )
        end
      end
    end

    context 'as a not enrolled user' do
      before do
        sign_in user: user, permissions: []
      end

      context 'without any available item' do
        it_behaves_like 'without any available item'
      end

      context 'with current item' do
        let!(:item) { create(:item, section:, open_mode: true) }

        its(:status) { is_expected.to eq 303 }

        it 'redirects to the current item' do
          expect(resume).to redirect_to course_item_path(
            course.course_code,
            short_uuid(item.id)
          )
        end
      end
    end
  end

  describe '#show' do
    context 'for course in preparation' do
      subject(:request) { get :show, params: {id: course.id} }

      let(:course) { create(:course, published: false, course_code: 'test') }

      before do
        course
      end

      context 'as anonymous user' do
        it 'cannot access the course' do
          expect { request }.to raise_error Status::NotFound
        end
      end

      context 'as logged in user' do
        before { sign_in user: create(:'account_service/user') }

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
      let(:placement) { ['Open4All'] }
      let(:course) { create(:'course_service/course', :active, course_code: 'the_course', placement:, title: 'Test Course', created_at: now - 2.weeks, updated_at: now - 1.week) }

      before do
        Stub.request(
          :course, :get, '/teachers',
          query: {course: course.id}
        ).to_return Stub.json([
          {id: teacher_id, name: 'John Doe'},
        ])
      end

      context 'as anonymous user' do
        it 'answers with a page' do
          expect(get_request.status).to eq 200
        end
      end

      context 'for logged-in users' do
        context 'w/ permission to see the course details' do
          before { sign_in user: user }

          it 'answers with a page' do
            expect(get_request.status).to eq 200
          end
        end
      end

      context 'for meta tags' do
        render_views

        subject(:course_details) { get_request; response.body }

        before { sign_in user: user, permissions: %w[course.course.show] }

        let(:get_request) { get :show, params: {id: course.course_code} }

        it 'has the correct title meta tag' do
          expect(course_details).to _have_xpath('html/head/title', text: 'Test Course')
        end

        it 'has the correct description' do
          expect(course_details).to _have_xpath("html/head/meta[@name='description']", content: 'This is a nice course about cool stuff')
        end

        it 'has no robots tag' do
          expect(course_details).not_to _have_xpath("html/head/meta[@name='robots']", content: 'noindex')
        end

        context 'without abstract' do
          let(:abstract) { nil }

          it 'has the correct description (falling back to course description)' do
            expect(course_details).to _have_xpath("html/head/meta[@name='description']", content: 'This is a nice course about cool stuff')
          end
        end

        it 'has the correct timestamps' do
          expect(course_details).to _have_xpath("html/head/meta[@name='dcterms.created']", content: course.created_at.iso8601)
          expect(course_details).to _have_xpath("html/head/meta[@name='dcterms.modified']", content: course.updated_at.iso8601)
        end

        it 'has no keywords' do
          expect(course_details).not_to _have_xpath("html/head/meta[@name='keywords']")
        end

        context 'with keyword classifiers' do
          let(:cluster) { create(:'course_service/cluster', id: 'topic') }
          let(:classifier_1) { create(:'course_service/classifier', cluster_id: cluster.id, title: 'p3k') }
          let(:classifier_2) { create(:'course_service/classifier', cluster_id: cluster.id, title: 'i18n') }

          before do
            course.classifiers << classifier_1
            course.classifiers << classifier_2
          end

          it 'has the correct keywords' do
            expect(course_details).to _have_xpath("html/head/meta[@name='keywords']", content: 'p3k, i18n')
          end

          context 'with additional topic classifier' do
            let(:classifier_3) { create(:'course_service/classifier', cluster_id: cluster.id, title: 'topic') }

            before do
              course.classifiers << classifier_3
            end

            it 'has the correct keywords' do
              content = course_details[/name="keywords" content="([^"]*)"/, 1]
              expect(content.split(', ')).to contain_exactly('p3k', 'i18n', 'topic')
            end
          end
        end

        it 'has the correct OpenGraph meta tags' do
          expect(course_details).to _have_xpath("html/head/meta[@property='og:title']", content: 'Test Course')
          expect(course_details).to _have_xpath("html/head/meta[@property='og:image']", content: '/assets/defaults/course-e42f443e.png')
          expect(course_details).to _have_xpath("html/head/meta[@property='og:type']", content: 'website')
          expect(course_details).to _have_xpath("html/head/meta[@property='og:url']", content: 'https://xikolo.de/learn/the_course')
          expect(course_details).to _have_xpath("html/head/meta[@property='og:description']", content: 'This is a nice course about cool stuff')
          expect(course_details).to _have_xpath("html/head/meta[@property='og:site_name']", content: 'Xikolo')
          expect(course_details).to _have_xpath("html/head/meta[@property='og:image:secure_url']", content: '/assets/defaults/course-e42f443e.png')
          expect(course_details).to _have_xpath("html/head/meta[@property='og:locale']", content: 'en')
        end

        context 'for hidden courses' do
          let(:placement) { [] }

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
          published: true,
          context_id: course_context.id,
        })
      end

      it 'redirects to the canonical course URL' do
        expect(response).to have_http_status :moved_permanently
        expect(response).to redirect_to course_url('test')
      end
    end
  end
end
