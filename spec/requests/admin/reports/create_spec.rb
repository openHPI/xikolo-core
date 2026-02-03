# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Reports: Create', type: :request do
  subject(:request) { post '/reports', params:, headers: }

  before do
    Stub.service(:learnanalytics, build(:'lanalytics:root'))
    Stub.request(:learnanalytics, :get, '/report_types')
      .to_return Stub.json([
        build(:'lanalytics:report_type', :course_report),
        build(:'lanalytics:report_type', :enrollment_statistics_report),
        build(:'lanalytics:report_type', :overall_course_summary_report),
      ])

    stub_report_creation
  end

  let(:headers) { {} }
  let(:user_id) { generate(:user_id) }

  let(:task_scope) { '' }
  let(:task_options) { {} }
  let(:report_attributes) do
    {
      task_type:,
      task_scope:,
      options: task_options,
    }
  end

  let(:params) { {task_type => report_attributes} }

  let(:stub_report_creation) { Stub.request(:learnanalytics, :post, '/report_jobs') }

  context 'for logged-in users' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }

    before { stub_user_request id: user_id, permissions: }

    context 'with permissions' do
      let(:permissions) { ['lanalytics.report.create'] }

      context 'with valid params' do
        context 'requesting a course report' do
          let(:task_type) { 'course_report' }
          let(:task_scope) { generate(:course_id) }
          let(:task_options) do
            {
              zip_password: 'secret_password',
              machine_headers: '1',
              de_pseudonymized: '0',
              include_access_groups: '1',
              include_profile: '1',
              include_auth: '0',
              include_analytics_metrics: '1',
              include_all_quizzes: '1',
            }
          end

          let(:stub_report_creation) do
            Stub.request(
              :learnanalytics, :post, '/report_jobs',
              body: {
                user_id:,
                task_type: report_attributes[:task_type],
                task_scope: report_attributes[:task_scope],
                options: {
                  zip_password: report_attributes[:options][:zip_password],
                  machine_headers: true,
                  de_pseudonymized: false,
                  include_access_groups: true,
                  include_profile: true,
                  include_auth: false,
                  include_analytics_metrics: true,
                  include_all_quizzes: true,
                },
              }
            )
          end

          it 'creates the report' do
            request

            # the zip_password is explicitly filtered out (sent in POST body)
            expect(response).to redirect_to reports_path(
              report_type: task_type,
              report_scope: task_scope,
              machine_headers: true,
              de_pseudonymized: false,
              include_access_groups: true,
              include_profile: true,
              include_auth: false,
              include_analytics_metrics: true,
              include_all_quizzes: true
            )
            expect(stub_report_creation).to have_been_requested
            expect(flash[:success].first).to eq 'The report was created successfully'
          end
        end

        context 'requesting an enrollment statistics report' do
          let(:task_type) { 'enrollment_statistics_report' }
          let(:task_options) do
            {
              zip_password: 'secret_password',
              machine_headers: '1',
              first_date: '2021-01-01',
              last_date: '2021-05-10',
              window_unit: 'days',
              window_size: '1',
              sliding_window: '1',
              include_all_classifiers: '1',
              include_active_users: '0',
            }
          end

          let(:stub_report_creation) do
            Stub.request(
              :learnanalytics, :post, '/report_jobs',
              body: {
                user_id:,
                task_type: report_attributes[:task_type],
                task_scope: report_attributes[:task_scope],
                options: {
                  zip_password: report_attributes[:options][:zip_password],
                  machine_headers: true,
                  first_date: '2021-01-01',
                  last_date: '2021-05-10',
                  window_unit: 'days',
                  window_size: '1',
                  sliding_window: true,
                  include_all_classifiers: true,
                  include_active_users: false,
                },
              }
            )
          end

          it 'creates the report' do
            request

            # the zip_password is explicitly filtered out (sent in POST body)
            expect(response).to redirect_to reports_path(
              report_type: task_type,
              report_scope: task_scope,
              machine_headers: true,
              first_date: '2021-01-01',
              last_date: '2021-05-10',
              window_unit: 'days',
              window_size: '1',
              sliding_window: true,
              include_all_classifiers: true,
              include_active_users: false
            )
            expect(stub_report_creation).to have_been_requested
            expect(flash[:success].first).to eq 'The report was created successfully'
          end
        end

        context 'requesting an overall course summary report' do
          let(:task_type) { 'overall_course_summary_report' }
          let(:task_options) do
            {
              zip_password: 'secret_password',
              machine_headers: '1',
              include_statistics: '0',
              end_date: '2021-05-10',
            }
          end

          let(:stub_report_creation) do
            Stub.request(
              :learnanalytics, :post, '/report_jobs',
              body: {
                user_id:,
                task_type: report_attributes[:task_type],
                task_scope: report_attributes[:task_scope],
                options: {
                  zip_password: report_attributes[:options][:zip_password],
                  machine_headers: true,
                  include_statistics: false,
                  end_date: '2021-05-10',
                },
              }
            )
          end

          it 'creates the report' do
            request

            # the zip_password is explicitly filtered out (sent in POST body)
            expect(response).to redirect_to reports_path(
              report_type: task_type,
              report_scope: task_scope,
              machine_headers: true,
              include_statistics: false,
              end_date: '2021-05-10'
            )
            expect(stub_report_creation).to have_been_requested
            expect(flash[:success].first).to eq 'The report was created successfully'
          end
        end
      end

      context 'and the report creation fails' do
        let(:task_type) { 'course_report' }

        let(:stub_report_creation) do
          Stub.request(:learnanalytics, :post, '/report_jobs')
            .to_return(Stub.response(status: 422))
        end

        it 'redirects the user to the report page with an error message' do
          request
          expect(response).to redirect_to reports_path
          expect(stub_report_creation).to have_been_requested
          expect(flash[:error].first).to eq 'We had a problem creating your report'
        end
      end
    end

    context 'without permissions' do
      let(:permissions) { [] }
      let(:task_type) { 'course_report' }

      it 'redirects to the start page' do
        request
        expect(response).to redirect_to root_url
        expect(stub_report_creation).not_to have_been_requested
      end
    end
  end

  context 'for anonymous users' do
    let(:task_type) { 'course_report' }

    it 'redirects to the start page' do
      request
      expect(response).to redirect_to root_url
      expect(stub_report_creation).not_to have_been_requested
    end
  end
end
