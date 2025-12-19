# frozen_string_literal: true

require 'spec_helper'

describe LtiController, type: :controller do
  let(:provider) { create(:lti_provider) }
  let(:exercise) { create(:lti_exercise, provider:) }
  let(:gradebook) { create(:lti_gradebook, exercise:) }

  let(:user) { create(:user, id: gradebook.user_id) }

  let!(:course) { create(:course, id: provider.course_id, course_code: 'the-course') }
  let!(:section) { create(:section, course:) }
  let!(:item) { create(:item, section:, content_id: exercise.id, content_type: 'lti_exercise') }

  before do
    stub_user id: user.id, email: 'jsmith@example.com', name: 'John Smith', context_id: course.context_id
  end

  describe 'GET #tool_launch' do
    subject(:tool_launch) do
      get :tool_launch, params: {course_id: 'the-course', id: item.id}
    end

    render_views

    context 'when submission deadline has passed' do
      let!(:item) { create(:item, section:, content_id: exercise.id, content_type: 'lti_exercise', submission_deadline: 1.day.ago) }

      it 'redirects with error message' do
        tool_launch
        expect(response).to redirect_to(course_item_url('the-course', item.id))
        expect(flash[:error]).to be_present
      end
    end

    context 'when the LTI provider has pseudonymized privacy' do
      let(:provider) { create(:lti_provider, :pseudonymized) }

      it 'contains a subset of user data' do
        tool_launch
        expect(response.body).to include 'input name="user_id"'
        expect(response.body).to include 'input name="lis_person_name_full"'
        expect(response.body).not_to include 'input name="lis_person_contact_email_primary"'
        expect(response.body).not_to include 'input name="lis_person_name_family"'
        expect(response.body).not_to include 'input name="lis_person_name_given"'
      end
    end

    context 'when the LTI provider has unprotected privacy' do
      let(:provider) { create(:lti_provider, :unprotected) }

      it 'contains user data' do
        tool_launch
        expect(response.body).to include 'input name="lis_person_contact_email_primary"'
        expect(response.body).to include 'input name="lis_person_name_family"'
        expect(response.body).to include 'input name="lis_person_name_given"'
        expect(response.body).to include 'input name="lis_person_name_full"'
      end
    end

    it 'sets the correct launch URL' do
      tool_launch
      expect(assigns(:launch).url).to eq('https://example.org/lti')
    end

    it 'contains the HTML form target mode' do
      tool_launch
      expect(response.body).to include '<form action="https://example.org/lti" id="launch-form" method="POST" target="_blank">'
    end
  end

  describe 'POST #tool_grading' do
    subject(:tool_grading) do
      post :tool_grading,
        body: request_body,
        params: {
          format: 'xml',
          course_id: 'the-course',
          id: item.id,
        }
    end

    context 'with a non-empty request' do
      let(:score) { 0.5 }
      let(:request_body) do
        # We need an unfrozen body due forcing encoding in controller
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <imsx_POXEnvelopeRequest xmlns="http://www.imsglobal.org/lis/oms1p0/pox">
            <imsx_POXHeader>
              <imsx_POXRequestHeaderInfo>
                <imsx_version>V1.0</imsx_version>
                <imsx_messageIdentifier>123456789</imsx_messageIdentifier>
              </imsx_POXRequestHeaderInfo>
            </imsx_POXHeader>
            <imsx_POXBody>
              <replaceResultRequest>
                <resultRecord>
                  <sourcedGUID>
                    <sourcedId>#{gradebook.id}</sourcedId>
                  </sourcedGUID>
                  <result>
                    <resultScore>
                      <language>en</language>
                      <textString>#{score}</textString>
                    </resultScore>
                  </result>
                </resultRecord>
              </replaceResultRequest>
            </imsx_POXBody>
          </imsx_POXEnvelopeRequest>
        XML
      end
      let(:consumer) do
        instance_double(
          IMS::LTI::ToolConsumer,
          request_oauth_nonce: 'nonce',
          request_oauth_timestamp: oauth_timestamp,
          valid_request?: valid_request
        )
      end
      let(:oauth_timestamp) { Time.now.to_i }

      before do
        expect(IMS::LTI::ToolConsumer).to receive(:new).once.and_return(consumer)
      end

      context 'with an invalidly signed request' do
        let(:valid_request) { false }

        it { is_expected.to have_http_status :unauthorized }
      end

      context 'with a validly signed request' do
        let(:valid_request) { true }

        context 'with an expired session' do
          let(:oauth_timestamp) { 180.minutes.ago.to_i }

          it { is_expected.to have_http_status :unauthorized }
        end

        context 'with a valid request and session' do
          let(:outcome_response) do
            instance_double(
              IMS::LTI::OutcomeResponse,
              :message_ref_identifier= => '123456789',
              :operation= => 'replaceResult',
              :severity= => 'status',
              :code_major= => 'success',
              :success? => true,
              :generate_response_xml => '<xml></xml>'
            )
          end

          let(:event_hash) do
            {
              'in_context' => {
                'course_id' => course.id,
                'provider_name' => 'Provider',
                'provider_start_url' => 'https://example.org/lti',
                'score' => score,
                'user_ip' => '0.0.0.0',
              },
              'resource' => {'uuid' => exercise.id, 'type' => 'lti'},
              'verb' => {'type' => 'SUBMITTED_LTI_V2'},
              'user' => {'uuid' => user.id},
              'timestamp' => nil,
              'with_result' => {},
            }
          end

          before do
            expect(IMS::LTI::OutcomeResponse)
              .to receive(:new).once
              .and_return(outcome_response)
          end

          it 'creates an LTI grade' do
            expect do
              tool_grading
            end.to change(Lti::Grade, :count).from(0).to(1)
          end

          context 'with LTI provider' do
            context 'non-global' do
              it 'publishes the xi-lanalytics LTI tracking event' do
                expect(Msgr).to receive(:publish).once.with(
                  event_hash,
                  hash_including(to: 'xikolo.web.exp_event.create')
                )
                tool_grading
              end
            end

            context 'global' do
              let(:provider) { create(:lti_provider, :global) }

              it 'publishes the xi-lanalytics LTI tracking event' do
                expect(Msgr).to receive(:publish).once.with(
                  event_hash,
                  hash_including(to: 'xikolo.web.exp_event.create')
                )
                tool_grading
              end
            end
          end

          it 'returns the generated XML response' do
            tool_grading
            expect(outcome_response).to have_received(:generate_response_xml).once
            expect(response.headers['Content-Type']).to include('application/xml')
          end

          it { is_expected.to have_http_status :ok }

          context 'with invalid score' do
            let(:score) { 1.5 }

            it { is_expected.to have_http_status :unprocessable_entity }

            it 'does not publish the xi-lanalytics LTI tracking event' do
              expect(Msgr).not_to receive(:publish).with(
                hash_including('verb' => {'type' => 'SUBMITTED_LTI'}),
                hash_including(to: 'xikolo.web.exp_event.create')
              )
              tool_grading
            end
          end
        end
      end
    end

    context 'with an empty request' do
      let(:request_body) { '' }

      it { is_expected.to have_http_status :unauthorized }
    end
  end

  describe 'GET #tool_return' do
    it 'redirects to the item' do
      get :tool_return, params: {
        course_id: 'the-course',
        format: 'xml',
        id: item.id,
        section_id: section.id,
      }

      expect(response).to redirect_to(course_item_url('the-course', item.id))
    end

    context 'when including a message' do
      let(:message) { 'Well done.' }

      it 'displays the message to the user' do
        get :tool_return, params: {
          course_id: 'the-course',
          format: 'xml',
          id: item.id,
          lti_msg: message,
        }

        expect(flash[:notice].first).to eq(message)
      end
    end

    context 'when including an error message' do
      let(:message) { 'Something went wrong.' }

      it 'displays the message to the user' do
        get :tool_return, params: {
          course_id: 'the-course',
          format: 'xml',
          id: item.id,
          lti_errormsg: message,
        }

        expect(flash[:error].first).to eq(message)
      end
    end
  end

  describe 'LtiController::ToolGrading' do
    subject(:grading) do
      post_request
      LtiController::ToolGrading.new(request, course)
    end

    let(:post_request) do
      post :tool_grading,
        body: request_body,
        params: {
          format: 'xml',
          course_id: 'the-course',
          id: item.id,
        }
    end
    let(:score) { 0.5 }
    let(:request_body) do
      # We need an unfrozen body due forcing encoding in controller
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <imsx_POXEnvelopeRequest xmlns="http://www.imsglobal.org/lis/oms1p0/pox">
          <imsx_POXHeader>
            <imsx_POXRequestHeaderInfo>
              <imsx_version>V1.0</imsx_version>
              <imsx_messageIdentifier>123456789</imsx_messageIdentifier>
            </imsx_POXRequestHeaderInfo>
          </imsx_POXHeader>
          <imsx_POXBody>
            <replaceResultRequest>
              <resultRecord>
                <sourcedGUID>
                  <sourcedId>#{gradebook.id}</sourcedId>
                </sourcedGUID>
                <result>
                  <resultScore>
                    <language>en</language>
                    <textString>#{score}</textString>
                  </resultScore>
                </result>
              </resultRecord>
            </replaceResultRequest>
          </imsx_POXBody>
        </imsx_POXEnvelopeRequest>
      XML
    end

    describe '#response_successful?' do
      context 'with a valid score' do
        it { is_expected.to be_response_successful }
      end

      context 'with score == 0' do
        let(:score) { 0 }

        it { is_expected.to be_response_successful }

        it '(grading status)' do
          expect(grading.send(:lti_response)).to be_success
        end
      end

      context 'with an invalid score' do
        let(:score) { 42 }

        it { is_expected.not_to be_response_successful }

        it '(grading status)' do
          expect(grading.send(:lti_response)).to be_failure
        end
      end

      context 'with an empty score' do
        let(:score) { nil }

        it { is_expected.not_to be_response_successful }

        it '(grading status)' do
          expect(grading.send(:lti_response)).to be_failure
        end
      end

      context 'unsupported request (type)' do
        let(:request_body) do
          # We need an unfrozen body due forcing encoding in controller
          <<~XML
            <?xml version="1.0" encoding="UTF-8"?>
            <imsx_POXEnvelopeRequest xmlns="http://www.imsglobal.org/lis/oms1p0/pox">
              <imsx_POXHeader>
                <imsx_POXRequestHeaderInfo>
                  <imsx_version>V1.0</imsx_version>
                  <imsx_messageIdentifier>123456789</imsx_messageIdentifier>
                </imsx_POXRequestHeaderInfo>
              </imsx_POXHeader>
              <imsx_POXBody>
                <readResultRequest>
                  <resultRecord>
                    <sourcedGUID>
                      <sourcedId>#{gradebook.id}</sourcedId>
                    </sourcedGUID>
                  </resultRecord>
                </readResultRequest>
              </imsx_POXBody>
            </imsx_POXEnvelopeRequest>
          XML
        end

        it { is_expected.not_to be_response_successful }

        it '(grading status)' do
          expect(grading.send(:lti_response)).to be_unsupported
        end
      end
    end
  end
end
