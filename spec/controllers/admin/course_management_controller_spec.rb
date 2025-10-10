# frozen_string_literal: true

require 'spec_helper'

describe Admin::CourseManagementController, type: :controller do
  let(:user) { stub_user id: user_id, language: 'en', permissions: }
  let(:permissions) { [] }
  let(:user_id) { SecureRandom.uuid }
  let(:enroll_user_id) { SecureRandom.uuid }
  let(:course_id) { SecureRandom.uuid }
  let(:submission_id) { SecureRandom.uuid }
  let(:snapshot_id) { SecureRandom.uuid }
  let(:course_code) { 'the-code' }

  around {|example| Timecop.freeze(&example) }

  before do
    user

    Stub.service(:account, build(:'account:root'))

    Stub.service(:course, build(:'course:root'))
    Stub.request(
      :course, :get, '/courses'
    ).to_return Stub.json([])
    Stub.request(
      :course, :get, "/courses/#{course_id}"
    ).to_return Stub.json({
      id: course_id,
      course_code:,
      context_id: course_context_id,
      created_at: DateTime.new(2015, 7, 12),
    })
    Stub.request(
      :course, :post, '/enrollments',
      body: hash_including(user_id: enroll_user_id, course_id:)
    ).to_return Stub.json({
      course_id:,
      user_id: enroll_user_id,
    })

    Stub.service(:quiz, build(:'quiz:root'))
    Stub.request(
      :quiz, :get, "/quiz_submissions/#{submission_id}"
    ).to_return Stub.json({
      id: submission_id,
    })
    Stub.request(
      :quiz, :get, "/quiz_submission_snapshots/#{snapshot_id}"
    ).to_return Stub.json({
      id: snapshot_id,
    })
  end

  describe '#preview_quizzes' do
    subject(:action) { -> { post :preview_quizzes, params: } }

    let(:request_context_id) { course_context_id }
    let(:permissions) { ['course.content.edit'] }
    let(:xmlfile) { fixture_file_upload('spec/support/files/course/quizzes.xml', 'text/xml') }
    let(:xmlstring) { File.read(xmlfile.path) }
    let(:params) { {id: course_id, xml: xmlfile} }

    let(:quiz_request) do
      Stub.request(:quiz, :post, '/quizzes', query: {preview: true}).to_return(quiz_response)
    end

    before { quiz_request }

    context 'with successful request' do
      let(:response_data) do
        {
          params: {
            course_code:,
            course_id:,
            xml: xmlstring,
          },
          quizzes: {quizzes: [quiz: {name: 'My Test'}]},
        }.to_json
      end

      let(:quiz_response) do
        {
          body: response_data,
          status: 200,
          headers: {'Content-Type' => 'text/xml; charset=utf-8'},
        }
      end

      it 'got params and quizzes as json' do
        action.call
        expect(response.body).to eq response_data
        expect(response).to have_http_status :ok
      end
    end
  end

  describe '#import_quizzes' do
    subject(:action) { -> { post :import_quizzes, params: } }

    let(:request_context_id) { course_context_id }
    let(:permissions) { ['course.content.edit'] }
    let(:xmlstring) { File.read('spec/support/files/course/quizzes.xml') }
    let(:params) { {id: course_id, xml: xmlstring} }

    let(:quiz_request) do
      Stub.request(:quiz, :post, '/quizzes',
        body: hash_including(
          course_code:,
          course_id:,
          xml: xmlstring
        )).to_return(quiz_response)
    end
    let(:quiz_response) { {status: 200} }

    before { quiz_request }

    context 'with successfull response' do
      it 'returns ok' do
        action.call
        expect(response.body).to eq '{"success":"Ok"}'
        expect(response).to have_http_status :ok
      end
    end

    context 'with errors from quiz service' do
      let(:errors) { ['1st parameter error', '2nd parameter error'] }
      let(:quiz_response) do
        {
          body: {errors:}.to_json,
          status: 422,
          headers: {'Content-Type' => 'application/json'},
        }
      end

      let(:response_body) do
        {error: errors}.to_json
      end

      it 'returns paramters errors' do
        action.call
        expect(response.body).to eq response_body
        expect(response).to have_http_status :unprocessable_entity
      end
    end
  end

  describe '#import_quizzes_by_service' do
    subject(:action) { -> { post :import_quizzes_by_service, params: } }

    let(:request_context_id) { course_context_id }
    let(:permissions) { ['course.content.edit'] }
    let(:xml) do
      # We need an unfrozen string here as the controller
      # enforces an encoding on the (stubbed) response body
      +'xml_string_from_service'
    end
    let(:params) { {id: course_id, spreadsheet: 'abc', worksheet: 'xyz'} }

    let(:quiz_request) do
      Stub.request(:quiz, :post, '/quizzes',
        body: hash_including(
          course_code:,
          course_id:,
          xml:
        )).to_return(status: 200)
    end

    before do
      quiz_request

      Stub.enable :quizimporter
      Stub.request(
        :quizimporter, :get, '/',
        query: {
          worksheet: 'xyz',
          spreadsheet: 'abc',
          course_code:,
        }
      ).to_return(service_response)
    end

    context 'with successful request' do
      let(:service_response) do
        {
          body: xml,
          status: 200,
          headers: {'Content-Type' => 'text/xml; charset=utf-8'},
        }
      end

      it 'sets a proper flash message' do
        action.call
        expect(flash[:success]).to include 'Quizzes successfully imported!'
      end

      it 'sends XML to quiz service' do
        action.call
        expect(quiz_request).to have_been_requested
      end
    end

    context 'with invalid worksheet' do
      let(:service_response) do
        {
          # We need an unfrozen string here as the controller
          # enforces an encoding on the (stubbed) response body
          body: +'Invalid worksheet',
          status: 405,
          headers: {'Content-Type' => 'text/plain; charset=utf-8'},
        }
      end

      it 'sets an error flash message' do
        action.call
        expect(flash[:error]).to include 'Invalid worksheet'
        expect(quiz_request).not_to have_been_requested
      end
    end
  end

  describe 'POST convert_submission' do
    subject(:action) { -> { post :convert_submission, params: } }

    let(:request_context_id) { course_context_id }
    let(:params) { {id: course_id} }

    before do
      request.env['HTTP_REFERER'] = 'http://test.host/where_i_came_from'
    end

    context 'as user' do
      it 'redirects' do
        action.call
        expect(response).to have_http_status :found
      end
    end

    context 'not logged in' do
      let(:user) { nil }

      it 'redirects' do
        action.call
        expect(response).to have_http_status :found
      end
    end

    context 'with quiz.submission.manage permission' do
      let(:permissions) { ['quiz.submission.manage', 'course.content.access'] }

      it 'is successful' do
        action.call
        expect(response).to redirect_to 'http://test.host/where_i_came_from'
      end

      context 'with submission and snapshot params' do
        let(:params) { {id: course_id, submission_id:, snapshot_id:} }

        it 'is successful' do
          action.call
          expect(response).to have_http_status :found
        end

        it 'sets a flash error message' do
          action.call
          expect(flash[:success]).to include 'Submission was successfully converted from existing snapshot!'
        end
      end
    end
  end
end
