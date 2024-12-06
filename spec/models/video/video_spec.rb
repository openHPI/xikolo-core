# frozen_string_literal: true

require 'spec_helper'

describe Video::Video, type: :model do
  subject(:video) { described_class.create!(params.merge(pip_stream_id: stream.id)) }

  let(:params) { attributes_for(:video) }
  let(:stream) { create(:stream) }

  describe '(deletion)' do
    before { video }
    around {|example| perform_enqueued_jobs(&example) }

    it 'deletes the video' do
      expect { video.destroy }.to change(Video::Video, :count).from(1).to(0)
    end

    context 'with attached reading material' do
      let(:params) { super().merge reading_material_uri: 's3://xikolo-public/reading_material.pdf' }

      let!(:delete_stub) do
        stub_request(
          :delete,
          'https://s3.xikolo.de/xikolo-public/reading_material.pdf'
        )
      end

      it 'deletes the referenced S3 object' do
        video.destroy
        expect(delete_stub).to have_been_requested
      end

      context 'with cloned video' do
        before do
          create(:video, reading_material_uri: video.reading_material_uri)
        end

        it 'does not remove the attached file' do
          video.destroy
          expect(delete_stub).not_to have_been_requested
        end
      end
    end

    context 'with an empty description' do
      let(:params) { attributes_for(:video).merge(description: nil) }

      it 'deletes the video' do
        expect { video.destroy }.to change(Video::Video, :count).from(1).to(0)
      end
    end
  end
end
