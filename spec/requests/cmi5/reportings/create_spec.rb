# frozen_string_literal: true

require 'spec_helper'

describe 'CMI5: Reportings: Create', type: :request do
  let(:user) { create(:'account_service/user') }
  let(:item) { create(:cmi5_item) }
  let(:course) { create(:'course_service/course', :active) }
  let(:section) { create(:'course_service/section', course:) }
  let(:course_item) do
    create(
      :'course_service/item',
      section:,
      content_type: 'cmi5',
      content_id: item.id,
      exercise_type: 'selftest',
      max_dpoints: 100
    )
  end
  let(:enrollment) do
    create(
      :'course_service/enrollment',
      course:,
      user:
    )
  end
  let(:statement_id) { SecureRandom.uuid }
  let(:activity_id) { Cmi5::Item.activity_id(item.id) }
  let(:statement) { {id: statement_id} }

  def encode_basic_credentials(token)
    Base64.strict_encode64("#{token}:")
  end

  def authorization_header(encoded_credentials)
    {'Authorization' => "Basic #{encoded_credentials}"}
  end

  def create_reporting_auth_token(item_id:)
    post '/cmi5/tokens', params: {id: item_id}, as: :json

    response.parsed_body.fetch('auth-token')
  end

  def post_reporting(authorization: nil)
    headers = authorization ? authorization_header(authorization) : {}

    post '/cmi5/reportings/statements', params: statement, headers:, as: :json
  end

  def scoring_statement(verb:, success:, scaled: nil)
    result = {success:}
    result[:score] = {scaled:} unless scaled.nil?

    {
      id: statement_id,
      object: {
        id: activity_id,
      },
      verb: {
        id: "http://adlnet.gov/expapi/verbs/#{verb}",
      },
      result:,
    }
  end

  describe 'with authenticated user' do
    before do
      sign_in(user: user)
    end

    describe 'with valid token from tokens endpoint' do
      before do
        course_item
        enrollment
      end

      it 'returns the statement ID' do
        auth_token = create_reporting_auth_token(item_id: item.id)

        post_reporting(authorization: auth_token)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq([statement_id])
      end

      context 'with a passed AU statement' do
        let(:statement) { scoring_statement(verb: 'passed', success: true) }

        it 'persists full course points' do
          auth_token = create_reporting_auth_token(item_id: item.id)

          expect do
            post_reporting(authorization: auth_token)
          end.to change(CourseService::Result, :count).by(1)

          expect(response).to have_http_status(:ok)
          expect(CourseService::Result.find(statement_id)).to have_attributes(
            user_id: user.id,
            item_id: course_item.id,
            dpoints: 100
          )
        end

        it 'reuses the statement ID when the AU retries the request' do
          auth_token = create_reporting_auth_token(item_id: item.id)

          expect do
            2.times { post_reporting(authorization: auth_token) }
          end.to change(CourseService::Result, :count).by(1)

          expect(response).to have_http_status(:ok)
          expect(CourseService::Result.find(statement_id)).to have_attributes(
            user_id: user.id,
            item_id: course_item.id,
            dpoints: 100
          )
        end
      end

      context 'with a passed AU statement with a scaled score' do
        let(:statement) { scoring_statement(verb: 'passed', success: true, scaled: 0.75) }

        it 'persists the scaled score multiplied with the item score' do
          auth_token = create_reporting_auth_token(item_id: item.id)

          expect do
            post_reporting(authorization: auth_token)
          end.to change(CourseService::Result, :count).by(1)

          expect(response).to have_http_status(:ok)
          expect(CourseService::Result.find(statement_id)).to have_attributes(
            user_id: user.id,
            item_id: course_item.id,
            dpoints: 75
          )
        end
      end

      context 'with a passed AU statement with a fractional scaled score' do
        let(:statement) { scoring_statement(verb: 'passed', success: true, scaled: 0.336) }

        it 'rounds the resulting course points' do
          auth_token = create_reporting_auth_token(item_id: item.id)

          expect do
            post_reporting(authorization: auth_token)
          end.to change(CourseService::Result, :count).by(1)

          expect(response).to have_http_status(:ok)
          expect(CourseService::Result.find(statement_id)).to have_attributes(
            user_id: user.id,
            item_id: course_item.id,
            dpoints: 34
          )
        end
      end

      context 'with a failed AU statement with a scaled score' do
        let(:statement) { scoring_statement(verb: 'failed', success: false, scaled: 0.3) }

        it 'persists the scaled score multiplied with the item score' do
          auth_token = create_reporting_auth_token(item_id: item.id)

          expect do
            post_reporting(authorization: auth_token)
          end.to change(CourseService::Result, :count).by(1)

          expect(response).to have_http_status(:ok)
          expect(CourseService::Result.find(statement_id)).to have_attributes(
            user_id: user.id,
            item_id: course_item.id,
            dpoints: 30
          )
        end
      end

      context 'with a failed AU statement' do
        let(:statement) { scoring_statement(verb: 'failed', success: false) }

        it 'persists zero course points' do
          auth_token = create_reporting_auth_token(item_id: item.id)

          expect do
            post_reporting(authorization: auth_token)
          end.to change(CourseService::Result, :count).by(1)

          expect(response).to have_http_status(:ok)
          expect(CourseService::Result.find(statement_id)).to have_attributes(
            user_id: user.id,
            item_id: course_item.id,
            dpoints: 0
          )
        end
      end

      context 'with a passed statement for a sub-activity' do
        let(:statement) do
          {
            id: statement_id,
            object: {
              id: 'urn:example:question',
            },
            verb: {
              id: 'http://adlnet.gov/expapi/verbs/passed',
            },
            result: {
              success: true,
            },
          }
        end

        it 'accepts the statement without persisting course points' do
          auth_token = create_reporting_auth_token(item_id: item.id)

          expect do
            post_reporting(authorization: auth_token)
          end.not_to change(CourseService::Result, :count)

          expect(response).to have_http_status(:ok)
        end
      end

      context 'with a completed AU statement' do
        let(:statement) do
          {
            id: statement_id,
            object: {
              id: activity_id,
            },
            verb: {
              id: 'http://adlnet.gov/expapi/verbs/completed',
            },
            result: {
              completion: true,
            },
          }
        end

        it 'accepts the statement without persisting course points' do
          auth_token = create_reporting_auth_token(item_id: item.id)

          expect do
            post_reporting(authorization: auth_token)
          end.not_to change(CourseService::Result, :count)

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to eq([statement_id])
        end
      end

      context 'with a passed AU statement for an ungraded item' do
        let(:course_item) do
          create(
            :'course_service/item',
            section:,
            content_type: 'cmi5',
            content_id: item.id,
            exercise_type: nil,
            max_dpoints: nil
          )
        end
        let(:statement) { scoring_statement(verb: 'passed', success: true) }

        it 'accepts the statement without persisting course points' do
          auth_token = create_reporting_auth_token(item_id: item.id)

          expect do
            post_reporting(authorization: auth_token)
          end.not_to change(CourseService::Result, :count)

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to eq([statement_id])
        end
      end

      context 'with a passed AU statement for a non-self-test item' do
        let(:course_item) do
          create(
            :'course_service/item',
            section:,
            content_type: 'cmi5',
            content_id: item.id,
            exercise_type: 'main',
            max_dpoints: nil
          ).tap do |course_item|
            course_item.update_column(:max_dpoints, 100)
          end
        end
        let(:statement) { scoring_statement(verb: 'passed', success: true) }

        it 'accepts the statement without persisting course points' do
          auth_token = create_reporting_auth_token(item_id: item.id)

          expect do
            post_reporting(authorization: auth_token)
          end.not_to change(CourseService::Result, :count)

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to eq([statement_id])
        end
      end
    end

    context 'with a passed AU statement but no active enrollment' do
      let(:enrollment) { nil }
      let(:statement) { scoring_statement(verb: 'passed', success: true) }

      before { course_item }

      it 'returns 401 Unauthorized without persisting course points' do
        token = Cmi5::TokensController.verifier.generate(
          {item_id: item.id},
          purpose: :cmi5_reporting,
          expires_in: 2.hours
        )

        expect do
          post_reporting(authorization: encode_basic_credentials(token))
        end.not_to change(CourseService::Result, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'without authenticated user' do
    it 'returns 401 Unauthorized' do
      token = Cmi5::TokensController.verifier.generate(
        {item_id: item.id},
        purpose: :cmi5_reporting,
        expires_in: 2.hours
      )

      post_reporting(authorization: encode_basic_credentials(token))

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to include('error' => 'Unauthorized')
    end
  end

  describe 'with authenticated user and invalid authorization' do
    before do
      sign_in(user: user)
    end

    context 'when Authorization header is malformed' do
      it 'returns 401 Unauthorized' do
        post '/cmi5/reportings/statements',
          params: statement,
          headers: {'Authorization' => 'InvalidFormat'},
          as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to include('error' => 'Unauthorized')
      end
    end
  end
end
