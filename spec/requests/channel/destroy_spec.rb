# frozen_string_literal: true

require 'spec_helper'

describe 'Channel: destroy', type: :request do
  subject(:destroy_channel) { delete "/channels/#{channel.id}", headers: }

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:channel) do
    create(
      :channel,
      code: 'the-channel',
      stage_visual_uri: 's3://xikolo-public/channels/1/stage_visual_v1.jpg',
      stage_statement: 'Channel Stage'
    )
  end
  let(:course) { create(:course, channels: [channel]) }

  let(:permissions) { %w[course.channel.delete] }
  let(:page) { Capybara.string(response.body) }

  let(:delete_stub) do
    Stub.request(
      :course, :delete, "/channels/#{channel.code}"
    ).to_return Stub.json({}, status: 204)
  end

  before do
    channel
    course
    stub_user_request(permissions:)
  end

  it 'deletes the channel' do
    expect { destroy_channel }.to change(Course::Channel, :count).from(1).to(0)
  end

  it 'deletes the channel without deleting the associated courses' do
    expect { destroy_channel }.not_to change(Course::Course, :count)
    expect(course.reload.channels).to be_empty
    expect(destroy_channel).to redirect_to admin_channels_path
    expect(flash[:notice].first).to eq I18n.t(:'flash.notice.channel_deleted')
  end
end
