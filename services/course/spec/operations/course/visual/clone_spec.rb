# frozen_string_literal: true

require 'spec_helper'

describe Course::Visual::Clone do
  subject(:operation) { described_class.call(old_visual, course) }

  let!(:course) { create(:course, :active) }
  let!(:old_visual) { create(:visual, :with_video) }
  let!(:old_video) { old_visual&.video }
  let(:new_visual) { course.visual }
  let(:new_video) { new_visual.video }
  let(:encoded_course_id) { UUID4(course.id).to_s(format: :base62) }

  let!(:copy_visual) do
    stub_request(
      :put, %r{https://s3.xikolo.de/xikolo-public/courses/[a-zA-Z0-9]+/[a-zA-Z0-9]+/course_visual.png}
    ).and_return(
      status: 200,
      body: '<xml></xml>'
    )
  end

  context 'with both an image and a teaser video' do
    it 'copies image file' do
      operation
      expect(copy_visual).to have_been_requested
    end

    it 'clones the visual' do
      expect { operation }.to change(Duplicated::Visual, :count).from(1).to(2)
      expect(new_visual.course_id).to eq course.id
    end

    it 'updates the associated image' do
      operation
      expect(new_visual.image_uri).not_to eq old_visual.image_uri
      expect(new_visual.image_uri).to match(%r{s3://xikolo-public/courses/#{encoded_course_id}/encodedUUUID/course_visual.png})
    end

    it 'clones the related teaser video' do
      expect { operation }.to change(Duplicated::Video, :count).from(1).to(2)
      expect(new_video.pip_stream_id).to eq(old_video.pip_stream_id)
    end

    context 'when the teaser video has subtitles' do
      let!(:subtitle) { create(:subtitle, video: old_video) }
      let!(:old_cue) do
        create(:subtitle_cue, subtitle:, start: 10.seconds, stop: 20.seconds)
      end
      let(:new_subtitle) { new_video.subtitles.first }
      let(:new_cue) { new_subtitle.cues.first }

      it 'clones subtitles to the new video' do
        expect { operation }.to change(Duplicated::Subtitle, :count).from(1).to(2)
        expect(new_video.reload.subtitles.count).to eq 1
        expect(new_subtitle.attributes.except('id')).to match(
          hash_including(
            'lang' => 'en',
            'automatic' => false,
            'video_id' => new_video.id
          )
        )
      end

      it 'clones cues of each subtitle' do
        expect { operation }.to change(Duplicated::SubtitleCue, :count).from(1).to(2)
        expect(new_subtitle.reload.cues.count).to eq(1)
      end

      it 'copies the same values of existing clues' do
        operation
        cue = Duplicated::SubtitleCue.find(old_cue.id)
        expect(new_cue).to match an_object_having_attributes(
          subtitle_id: new_subtitle.id,
          identifier: cue.identifier,
          start: 10.seconds,
          stop:  20.seconds,
          text: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'
        )
      end
    end

    it 'returns the cloned visual' do
      expect(operation).to eq new_visual
      expect(new_visual).to be_persisted
    end
  end

  context 'with an image only' do
    let(:old_visual) { create(:visual) }
    let(:old_video) { nil }

    it 'clones the visual' do
      expect { operation }.to change(Duplicated::Visual, :count).from(1).to(2)
      expect(new_visual.course_id).to eq course.id
    end

    it 'updates the associated image' do
      operation
      expect(new_visual.image_uri).not_to eq old_visual.image_uri
      expect(new_visual.image_uri).to match(%r{s3://xikolo-public/courses/#{encoded_course_id}/encodedUUUID/course_visual.png})
    end

    it 'does not create an associated teaser video' do
      expect { operation }.not_to change(Duplicated::Video, :count)
      expect(new_visual.video).to be_nil
    end
  end

  context 'with a teaser video only' do
    let(:old_visual) { create(:visual, :with_video, image_uri: nil) }

    it 'clones the visual' do
      expect { operation }.to change(Duplicated::Visual, :count).from(1).to(2)
      expect(new_visual.course_id).to eq course.id
    end

    it 'does not update the associated image' do
      operation
      expect(new_visual.image_uri).to be_nil
    end

    it 'clones the associated existing teaser video' do
      expect { operation }.to change(Duplicated::Video, :count).from(1).to(2)
      expect(new_visual.video_id).to eq(new_video.id)
      expect(new_video.pip_stream_id).to eq(old_video.pip_stream_id)
    end
  end

  context 'without an existing visual' do
    let(:old_visual) { nil }
    let(:old_video) { nil }

    it 'does not clone any visual' do
      expect { operation }.not_to change(Duplicated::Visual, :count).from(0)
    end

    it 'does not clone any video' do
      expect { operation }.not_to change(Duplicated::Video, :count).from(0)
    end

    it 'does not raise an error' do
      expect { operation }.not_to raise_error
    end
  end

  describe 'error handling' do
    context 'when no s3 file for the old image is found' do
      before do
        stub_request(
          :put, %r{https://s3.xikolo.de/xikolo-public/courses/[a-zA-Z0-9]+/[a-zA-Z0-9]+/course_visual.png}
        ).and_return(
          status: 404
        )
      end

      context 'with both image and teaser video' do
        it 'cloning the old image fails gracefully' do
          expect { operation }.not_to raise_error
        end

        it 'does clone a visual' do
          expect { operation }.to change(Duplicated::Visual, :count).from(1).to(2)
        end

        it 'does not update the associated image' do
          operation
          expect(new_visual.image_uri).to be_nil
        end

        it 'clones the related teaser video' do
          expect { operation }.to change(Duplicated::Video, :count).from(1).to(2)
          expect(new_video.pip_stream_id).to eq(old_video.pip_stream_id)
        end
      end

      context 'with image only' do
        let(:old_visual) { create(:visual) }
        let(:old_video) { nil }

        it 'fails gracefully' do
          expect { operation }.not_to raise_error
        end

        it 'does not clone a visual' do
          expect { operation }.not_to change(Duplicated::Visual, :count)
          expect(new_visual).to be_nil
        end
      end
    end

    context 'when an error occurs during the cloning of a teaser video' do
      # rubocop:disable RSpec/AnyInstance
      context 'with an existing visual' do
        before do
          allow_any_instance_of(Duplicated::Visual).to receive(:create_video!).with(pip_stream_id: old_video.pip_stream_id).and_raise(ActiveRecord::RecordInvalid)
        end

        it 'does not create a new teaser video' do
          expect { operation }.not_to change(Duplicated::Video, :count)
        end

        it 'fails gracefully' do
          expect { operation }.not_to raise_error
        end

        context 'when its existing video has subtitles' do
          before do
            subtitle = create(:subtitle, video: old_video)
            create(:subtitle_cue, subtitle:)
          end

          it 'fails gracefully' do
            expect { operation }.not_to raise_error
          end

          it 'does not clone subtitles' do
            expect { operation }.not_to change(Duplicated::Subtitle, :count)
          end

          it 'does not clone subtitle cues' do
            expect { operation }.not_to change(Duplicated::SubtitleCue, :count)
          end
        end
      end

      context 'without an existing visual for the new course' do
        before do
          course.visual = nil
          allow_any_instance_of(Duplicated::Visual).to receive(:create_video!).with(pip_stream_id: old_video.pip_stream_id).and_raise ActiveRecord::RecordInvalid
        end

        it 'fails gracefully' do
          expect { operation }.not_to raise_error
        end

        it 'does not clone a teaser video' do
          expect { operation }.not_to change(Duplicated::Video, :count)
        end

        it 'creates a visual' do
          operation
          expect(new_visual).to be_persisted
        end
      end
    end

    context 'when an error occurs during the cloning of subtitles' do
      before do
        subtitle = create(:subtitle, video: old_video)
        create(:subtitle_cue, subtitle:)
        allow_any_instance_of(Duplicated::Subtitle)
          .to receive(:clone).and_raise ActiveRecord::RecordInvalid
      end

      it 'fails gracefully' do
        expect { operation }.not_to raise_error
      end

      it 'does not clone subtitles' do
        expect { operation }.not_to change(Duplicated::Subtitle, :count)
      end

      it 'does not clone subtitle cues' do
        expect { operation }.not_to change(Duplicated::SubtitleCue, :count)
      end
    end
    # rubocop:enable RSpec/AnyInstance
  end
end
