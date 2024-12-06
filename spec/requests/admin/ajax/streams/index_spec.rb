# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Ajax: Streams: Index', type: :request do
  subject(:action) { get '/admin/streams', headers:, params: }

  let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:params) { {} }
  let(:json) { response.parsed_body }
  let(:provider) { create(:video_provider, :vimeo, name: 'my-provider') }
  let!(:stream) { create(:stream, title: 'some-stream', provider:) }

  before { stub_user_request(permissions: %w[video.video.index]) }

  it 'returns a JSON response with the ID and the text' do
    action
    expect(json).to contain_exactly hash_including(
      'id' => stream.id,
      'text' => 'some-stream (my-provider)'
    )
  end

  context 'when filtering by prefix' do
    let(:params) { super().merge(q: 'some') }

    before do
      create(:stream, title: 'another-stream', provider:)
    end

    it 'only includes matching video streams' do
      action
      expect(json).to contain_exactly hash_including(
        'id' => stream.id,
        'text' => 'some-stream (my-provider)'
      )
    end
  end
end
