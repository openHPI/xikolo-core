# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Reports: Index', type: :request do
  subject(:request) { get '/reports', headers: }

  let(:headers) { {} }

  before do
    Stub.service(:course, build(:'course:root'))
    Stub.service(:learnanalytics, build(:'lanalytics:root'))

    Stub.request(:learnanalytics, :get, '/report_types')
      .to_return Stub.json([build(:'lanalytics:report_type', :course_report)])

    Stub.request(:course, :get, '/courses', query: {alphabetic: true, public: true, groups: 'any'})
      .to_return Stub.json([
        build(:'course:course'),
        build(:'course:course'),
      ])

    Stub.request(:course, :get, '/classifiers', query: {cluster: 'category,reporting,topic'})
      .to_return Stub.json([
        build(:'course:classifier'),
        build(:'course:classifier'),
      ])
  end

  context 'for logged-in users' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }
    let(:user_id) { generate(:user_id) }
    let(:masqueraded) { false }

    before do
      stub_user_request id: user_id, permissions:, masqueraded:
    end

    context 'with permissions' do
      let(:permissions) { ['lanalytics.report.create'] }

      it 'renders the index page' do
        request
        expect(response).to render_template :index
      end

      context 'as an ajax request' do
        let(:headers) { super().merge('X-Requested-With': 'XMLHttpRequest') }
        let(:jobs) do
          [
            {
              id: SecureRandom.uuid,
              task_type: 'course_report',
              status: 'done',
              annotation: 'My Course Report',
              download_url: 'https://example.com/the_report.zip',
            },
          ]
        end

        before do
          Stub.request(:learnanalytics, :get, '/report_jobs', query: {user_id:, per_page: 200})
            .to_return Stub.json(jobs)
        end

        it 'renders the report jobs partial' do
          request
          expect(response.headers['Cache-Control']).to include('no-store')
          expect(response).to render_template partial: '_jobs'
          expect(response.body).to include('https://example.com/the_report.zip')
        end

        context 'as masqueraded user' do
          let(:masqueraded) { true }

          before { request }

          it 'renders the partial without download buttons' do
            expect(response).to render_template partial: '_jobs'
          end

          it 'includes the course_report job' do
            expect(response.body).to include('My Course Report')
          end

          it 'does not have a donwload link' do
            expect(response.body).not_to include('https://example.com/the_report.zip')
          end
        end
      end
    end

    context 'without permissions' do
      let(:permissions) { [] }

      it 'redirects to the start page' do
        request
        expect(response).to redirect_to root_url
      end
    end
  end

  context 'for anonymous users' do
    it 'redirects to the start page' do
      request
      expect(response).to redirect_to root_url
    end
  end
end
