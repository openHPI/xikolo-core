# frozen_string_literal: true

require 'spec_helper'

describe 'items/video/_form.html.erb', type: :view do
  helper_method :current_user

  subject(:rendered) do
    html = render_view
    Capybara.string(html)
  end

  let(:course) { create(:course) }
  let(:section) { create(:section, course:) }
  let(:item) { build(:item, :video, section:) }
  let(:video) { item.content }
  let(:subtitles_upload) { FileUpload.new(purpose: :video_subtitles, content_type: %w[application/zip text/vtt]) }
  let(:slides_upload) { FileUpload.new purpose: :video_slides }
  let(:reading_material_upload) { FileUpload.new purpose: :video_material }
  let(:transcript_upload) { FileUpload.new purpose: :video_transcript }
  let(:render_view) do
    render 'items/video/form', video:, item:, course:, subtitles_upload:, slides_upload:, reading_material_upload:, transcript_upload:
  end

  before do
    presigned = double(url: 'https://s3.example.com/upload', fields: {})
    allow(Xikolo::S3).to receive(:bucket_for).and_return(double(presigned_post: presigned))
  end

  context 'for a user with video.manage permission' do
    let(:current_user) { double(allowed?: true) }

    it 'does not render the inline upload card' do
      expect(rendered).to have_no_css('turbo-frame#video_upload_frame')
    end

    it 'still renders the four stream pickers' do
      %w[pip_stream lecturer_stream slides_stream subtitled_stream].each do |slot|
        expect(rendered).to have_css("select[name='video_video[#{slot}_id]']")
      end
    end
  end

  context 'for a user without video.manage permission' do
    let(:current_user) { double(allowed?: false) }

    it 'does not render the inline upload card' do
      expect(rendered).to have_no_css('turbo-frame#video_upload_frame')
    end

    it 'still renders the stream pickers' do
      expect(rendered).to have_css("select[name='video_video[pip_stream_id]']") # rubocop:disable Capybara/RSpec/SpecificMatcher
    end
  end
end
