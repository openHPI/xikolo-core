# frozen_string_literal: true

require 'spec_helper'

describe 'Go: Survey', type: :request do
  subject(:request) do
    get "/go/survey/#{id}", params:, headers:
  end

  before do
    xi_config <<~YML
      limesurvey_url: 'https://limesurvey.example.de'
    YML
  end

  let(:id) { 123_456 }
  let(:params) do
    {
      lang: 'en',
      course: 'howtocode2020',
    }
  end
  let(:headers) { {} }

  it 'redirects to LimeSurvey URL with correct query params' do
    request
    expect(response).to redirect_to %r{\Ahttps://limesurvey.example.de}

    query_params = Rack::Utils.parse_query(URI.parse(response.location).query)
    expect(query_params).to eq(
      'r' => 'survey/index',
      'sid' => '123456',
      'newtest' => 'Y',
      'xi_platform' => 'xikolo',
      'lang' => 'en',
      'course' => 'howtocode2020'
    )
  end

  context 'with tracking and sensitive query params' do
    let(:params) do
      super().merge(
        tracking_id: 654_321,
        referrer_page: 'https://myblog.com',
        user_id: 'a_real_user_id',
        another_allowed_param: 'this_is_fine'
      )
    end

    it 'redirects to LimeSurvey URL with sanitized query params' do
      request
      expect(response).to redirect_to %r{\Ahttps://limesurvey.example.de}

      query_params = Rack::Utils.parse_query(URI.parse(response.location).query)
      expect(query_params).to eq(
        'r' => 'survey/index',
        'sid' => '123456',
        'newtest' => 'Y',
        'xi_platform' => 'xikolo',
        'lang' => 'en',
        'course' => 'howtocode2020',
        'another_allowed_param' => 'this_is_fine'
      )
    end
  end

  context 'with authorized user' do
    let(:headers) do
      {Authorization: "Xikolo-Session session_id=#{stub_session_id}"}
    end
    let(:user_id) { '00000001-3100-4444-9999-000000000142' }

    before do
      stub_user_request id: user_id
    end

    it 'redirects to LimeSurvey URL with correct params and hashed user id' do
      request
      expect(response).to redirect_to %r{\Ahttps://limesurvey.example.de}

      query_params = Rack::Utils.parse_query(URI.parse(response.location).query)
      expect(query_params).to eq(
        'r' => 'survey/index',
        'sid' => '123456',
        'newtest' => 'Y',
        'xi_platform' => 'xikolo',
        'lang' => 'en',
        'course' => 'howtocode2020',
        'xi_pseudo_id' =>
          'bc7df476a6d9446ffe342d8edfb5d17e3d0d772be57512a549e714de99fb8b18'
      )
    end

    context 'with overwritten system query params' do
      let(:params) do
        super().merge(
          r: 'another_path',
          sid: 'another_id',
          newtest: 'N',
          xi_platform: 'another_platform',
          xi_pseudo_id: 'another_hashed_user_id'
        )
      end

      it 'redirects to LimeSurvey URL and ignores overwritten system params' do
        request
        expect(response).to redirect_to %r{\Ahttps://limesurvey.example.de}

        query_params = Rack::Utils.parse_query(
          URI.parse(response.location).query
        )
        expect(query_params).to eq(
          'r' => 'survey/index',
          'sid' => '123456',
          'newtest' => 'Y',
          'xi_platform' => 'xikolo',
          'lang' => 'en',
          'course' => 'howtocode2020',
          'xi_pseudo_id' =>
            'bc7df476a6d9446ffe342d8edfb5d17e3d0d772be57512a549e714de99fb8b18'
        )
      end
    end
  end
end
