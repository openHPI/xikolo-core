# frozen_string_literal: true

require 'spec_helper'

describe 'Channel: destroy', type: :request do
  subject(:destroy_channel) { delete "/channels/#{channel.id}" }

  let(:channel) do
    create(
      :'course_service/channel',
      code: 'the-channel',
      stage_visual_uri: 's3://xikolo-public/channels/1/stage_visual_v1.jpg',
      stage_statement: 'Channel Stage'
    )
  end
  let(:course) { create(:course, channels: [channel]) }

  let(:permissions) { %w[course.channel.delete] }
  let(:page) { Capybara.string(response.body) }
  let(:user) { create(:'account_service/user') }

  before do
    channel
    course
    stub_request(:delete, "#{test_s3_host}/xikolo-public/channels/1/stage_visual_v1.jpg")
      .to_return(status: 200)
    sign_in(user:)
    role = create(:'account_service/role', permissions:)
    create(:'account_service/grant', principal: user, role:)
  end

  it 'deletes the channel' do
    expect { destroy_channel }.to change(CourseService::Channel, :count).from(1).to(0)
  end

  it 'deletes the channel without deleting the associated courses' do
    expect { destroy_channel }.not_to change(CourseService::Course, :count)
    expect(course.reload.channels).to be_empty
    expect(destroy_channel).to redirect_to admin_channels_path
    expect(flash[:notice].first).to eq I18n.t(:'flash.notice.channel_deleted')
  end
end
