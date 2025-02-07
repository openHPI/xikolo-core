# frozen_string_literal: true

module XiIntegration
  module Seeds
    module Video
      class << self
        def seed!
          ::Video::Provider.delete_all
          provider = ::Video::Provider.create!(
            name: 'Gucci_Provider',
            token: '0c597a35c384f75c419634d070dd8713',
            provider_type: 'vimeo',
            credentials: {token: '0c597a35c384f75c419634d070dd8713'},
            default: true
          )
          pip_stream = ::Video::Stream.create!(
            title: 'the_course_internetworking_intro_pip',
            provider_id: provider.id,
            provider_video_id: '88330397',
            hd_url: 'https://player.vimeo.com/progressive_redirect/playback/88330397/rendition/720p?loc=external&oauth2_token_id=1212898389&signature=e76af2dc71141d3e7b5a815ce45da4f1bb3390e0fca9edf1d61dc2c2422cb319',
            sd_url: 'https://player.vimeo.com/progressive_redirect/playback/88330397/rendition/360p?loc=external&oauth2_token_id=1212898389&signature=7c9b9023980ebec9bd04902ff4836ebdb77e5204b12046c62e8ef570994370bd',
            hd_download_url: 'https://player.vimeo.com/progressive_redirect/download/88330397/container/4b2a7f28-5b30-44ca-8dd1-038c082776e5/5d8645eb/internetworking2014-w0-pip%20%28720p%29.mp4?expires=1644411648&loc=external&oauth2_token_id=1212898389&signature=0bc8dd8073be49ef4916c1d8bd35365e78ebc568f8e2426d322bb0c3846b47c2',
            sd_download_url: 'https://player.vimeo.com/progressive_redirect/download/88330397/container/4b2a7f28-5b30-44ca-8dd1-038c082776e5/21ad0010/internetworking2014-w0-pip%20%28360p%29.mp4?expires=1644411648&loc=external&oauth2_token_id=1212898389&signature=09f8710c5ad49133f54924ce5cd0f8562d6fae3a8e5aad450971bd10390e3dd7',
            width: 1280, height: 720,
            poster: 'http://b.vimeocdn.com/ts/466/745/466745444_1280.jpg',
            duration: 1678
          )
          lecturer_stream = ::Video::Stream.create!(
            provider_id: provider.id,
            title: 'the_course_internetworking_intro_lecturer',
            provider_video_id: '88329527',
            sd_url: 'http://player.vimeo.com/external/88329527.sd.mp4?s=b9a210b4b36ea04dc9b7eb2817f97d5a',
            width: 640, height: 360,
            poster: 'http://b.vimeocdn.com/ts/466/744/466744340_640.jpg'
          )
          slides_stream = ::Video::Stream.create!(
            provider_id: provider.id,
            title: 'the_course_internetworking_intro_slides',
            provider_video_id: '88329534',
            hd_url: 'http://player.vimeo.com/external/88329534.hd.mp4?s=548cb245c1e731c8dd931a806bad2ba0',
            sd_url: 'http://player.vimeo.com/external/88329534.sd.mp4?s=6aec28a1654c8b46794c22544a9dbbf7',
            width: 960, height: 720,
            poster: 'http://b.vimeocdn.com/ts/466/744/466744332_960.jpg'
          )
          description = <<~TEXT.strip
            Prof. Lena Babonsky introduces basic technical \
            concepts of the World Wide Web from a users perspective.
          TEXT
          video = ::Video::Video.create!(
            id: '00000003-3600-4444-9999-000000000001',
            title: 'WWW Introduction',
            description:,
            lecturer_stream_id: lecturer_stream.id,
            slides_stream_id: slides_stream.id
          )
          subtitle = video.subtitles.create!(lang: 'en')

          ::Video::SubtitleCue.create!(
            subtitle_id: subtitle.id,
            identifier: 1,
            start: 0.seconds,
            stop: 5.seconds,
            text: 'Valid interval.'
          )
          ::Video::SubtitleCue.create!(
            subtitle_id: subtitle.id,
            identifier: 2,
            start: 7.seconds,
            stop: 10.seconds,
            text: 'And another.'
          )
          ::Video::SubtitleCue.create!(
            subtitle_id: subtitle.id,
            identifier: 3,
            start: 12.seconds,
            stop: 13.seconds,
            text: 'This is okay.'
          )

          provider.streams.create!(
            provider_id: provider,
            title: 'the_course_intro_pip2',
            provider_video_id: '88330398',
            hd_url: 'https://player.vimeo.com/progressive_redirect/playback/88330398/rendition/720p?loc=external&oauth2_token_id=1212898389&signature=e76af2dc71141d3e7b5a815ce45da4f1bb3390e0fca9edf1d61dc2c2422cb319',
            sd_url: 'https://player.vimeo.com/progressive_redirect/playback/88330398/rendition/360p?loc=external&oauth2_token_id=1212898389&signature=7c9b9023980ebec9bd04902ff4836ebdb77e5204b12046c62e8ef570994370bd',
            hd_download_url: 'https://player.vimeo.com/progressive_redirect/download/88330398/container/4b2a7f28-5b30-44ca-8dd1-038c082776e5/5d8645eb/internetworking2014-w0-pip%20%28720p%29.mp4?expires=1644411648&loc=external&oauth2_token_id=1212898389&signature=0bc8dd8073be49ef4916c1d8bd35365e78ebc568f8e2426d322bb0c3846b47c2',
            sd_download_url: 'https://player.vimeo.com/progressive_redirect/download/88330398/container/4b2a7f28-5b30-44ca-8dd1-038c082776e5/21ad0010/internetworking2014-w0-pip%20%28360p%29.mp4?expires=1644411648&loc=external&oauth2_token_id=1212898389&signature=09f8710c5ad49133f54924ce5cd0f8562d6fae3a8e5aad450971bd10390e3dd7'
          )
          provider.streams.create!(
            title: 'the_course_intro_lecturer2',
            provider_video_id: '88329528',
            sd_url: 'http://player.vimeo.com/external/88329528.sd.mp4?s=b9a210b4b36ea04dc9b7eb2817f97d5a'
          )
          provider.streams.create!(
            title: 'the_course_intro_slides2',
            provider_video_id: '88329535',
            hd_url: 'http://player.vimeo.com/external/88329535.hd.mp4?s=548cb245c1e731c8dd931a806bad2ba0',
            sd_url: 'http://player.vimeo.com/external/88329535.sd.mp4?s=6aec28a1654c8b46794c22544a9dbbf7'
          )
          ::Video::Video.create!(
            id: '00000003-3100-4444-9999-000000000001',
            title: 'New Video Title in open mode',
            description: 'A previewable video item',
            pip_stream_id: pip_stream.id
          )
          ::Video::Video.create!(
            id: '00000003-3600-4444-9999-000000000003',
            title: 'New Unpublished Video Item',
            description: 'An unpublished video item',
            pip_stream_id: pip_stream.id
          )

          %w[
            00000003-3600-4444-9999-000000000004
            00000003-3600-4444-9999-000000000005
            00000003-3600-4444-9999-000000000006
            00000003-3600-4444-9999-000000000007
            00000003-3600-4444-9999-000000000008
          ].map.with_index(1) do |id, i|
            ::Video::Video.create!(
              id:,
              title: "Video title #{i}",
              pip_stream_id: pip_stream.id
            )
          end
        end
      end
    end
  end
end
