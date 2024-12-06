# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: ChannelsOrder: Update', type: :request do
  let(:update_channels_order) { post '/admin/channels/order', params:, headers: }
  let(:headers) { {} }
  let(:params) { {} }

  before do
    Stub.service(:course, build(:'course:root'))
  end

  context 'with permission' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }
    let(:permissions) { %w[course.channel.edit] }

    let(:patch_requests) do
      Stub.request(:course, :patch, '/channels/channel_id_1', body: hash_including({position: 1})).to_return Stub.json({}, status: 200)
      Stub.request(:course, :patch, '/channels/channel_id_2', body: hash_including({position: 2})).to_return Stub.json({}, status: 200)
      Stub.request(:course, :patch, '/channels/channel_id_3', body: hash_including({position: 3})).to_return Stub.json({}, status: 200)
    end

    before do
      stub_user_request(permissions:)
      patch_requests
    end

    context 'valid params' do
      let(:params) do
        {
          positions: %w[channel_id_1 channel_id_2 channel_id_3],
        }
      end

      it 'updates the channel positions' do
        update_channels_order
        expect(patch_requests).to have_been_requested
        expect(flash[:success].first).to eq 'The channel order has been updated.'
        expect(update_channels_order).to redirect_to admin_channels_url
      end
    end

    context 'invalid params' do
      let(:params) do
        {
          data: %w[channel_id_1 channel_id_2 channel_id_3],
        }
      end

      it 'does not send out patch requests' do
        update_channels_order
        expect(patch_requests).not_to have_been_requested
        expect(flash[:error].first).to include 'Something went wrong.'
        expect(update_channels_order).to redirect_to admin_channels_url
      end
    end
  end

  context 'without permissions' do
    it 'redirects the user' do
      update_channels_order
      expect(update_channels_order).to redirect_to root_url
    end
  end
end
