# frozen_string_literal: true

if Rails.env.integration?
  require 'webmock'
  require 'omniauth'

  XiIntegration.hook :test_setup do
    Rails.logger.debug 'Clearing rails cache'
    Rails.cache.clear
    seed!
  end

  OmniAuth.config.test_mode = true
  OmniAuth.config.add_mock :saml,
    provider: 'saml',
    uid: '1234567',
    info: {
      name: 'Lassie Fairy',
      email: 'lassie@company.com',
    },
    credentials: {},
    extra: {}

  module XiIntegration
    module Video
      RESPONSE_LIST_1 = <<~REQ
        {
          "paging": {
            "next": "/me/videos?page=2"
          },
          "data": [
            {
              "uri": "/videos/124597457",
              "name": "softwareanalytics2015-w6-5-pip",
              "duration": 1270,
              "width": 1280,
              "height": 720,
              "modified_time": "2017-10-17T16:00:00+02:00",
              "pictures": {
                "sizes": [
                  {
                    "type": "thumbnail",
                    "width": 1280,
                    "height": 720,
                    "link": "https://i.vimeocdn.com/video/514382489_1280.jpg"
                  },
                  {
                    "type": "thumbnail",
                    "width": 960,
                    "height": 540,
                    "link": "https://i.vimeocdn.com/video/514382489_960.jpg"
                  },
                  {
                    "type": "thumbnail",
                    "width": 640,
                    "height": 360,
                    "link": "https://i.vimeocdn.com/video/514382489_640.jpg"
                  },
                  {
                    "type": "thumbnail",
                    "width": 295,
                    "height": 166,
                    "link": "https://i.vimeocdn.com/video/514382489_295x166.jpg"
                  },
                  {
                    "type": "thumbnail",
                    "width": 200,
                    "height": 150,
                    "link": "https://i.vimeocdn.com/video/514382489_200x150.jpg"
                  },
                  {
                    "type": "thumbnail",
                    "width": 100,
                    "height": 75,
                    "link": "https://i.vimeocdn.com/video/514382489_100x75.jpg"
                  }
                ]
              },
              "files": [
                {
                  "quality": "hd",
                  "link": "https://player.vimeo.com/external/124597457.hd.mp4?s=a06a393f48378d7aaff7505dbe62d2f6&profile_id=113&oauth2_token_id=59539484",
                  "size": 300,
                  "md5": "md5hd"
                },
                {
                  "quality": "sd",
                  "link": "https://player.vimeo.com/external/124597457.sd.mp4?s=390874ae75806026d02cefad296c85a7&profile_id=112&oauth2_token_id=59539484",
                  "size": 200,
                  "md5": "md5sd"
                },
                {
                  "quality": "hls",
                  "link": "https://player.vimeo.com/external/124597457.m3u8?p=mobile,standard,high&s=fc0260d30d32e23c410849d2808ae635&oauth2_token_id=59539484",
                  "size": 100,
                  "md5": "md5hls"
                }
              ],
              "download": [
                {
                  "quality": "hd",
                  "link": "https://player.vimeo.com/external/124597457.hd.mp4?s=a06a393f48378d7aaff7505dbe62d2f6&profile_id=113&oauth2_token_id=59539484",
                  "size": 300
                },
                {
                  "quality": "sd",
                  "link": "https://player.vimeo.com/external/124597457.sd.mp4?s=390874ae75806026d02cefad296c85a7&profile_id=112&oauth2_token_id=59539484",
                  "size": 200
                }
              ]
            }
          ]
        }
      REQ

      RESPONSE_LIST_2 = <<~REQ
        {
          "paging": {
            "next": null
          },
          "data": [
            {
              "uri": "/videos/124597456",
              "name": "softwareanalytics2015-w6-5-desktop",
              "duration": 1262,
              "width": 960,
              "height": 720,
              "modified_time": "2017-10-17T16:01:00+02:00",
              "pictures": {
                "sizes": [
                  {
                    "type": "thumbnail",
                    "width": 1280,
                    "height": 960,
                    "link": "https://i.vimeocdn.com/video/514382490_1280.jpg"
                  },
                  {
                    "type": "thumbnail",
                    "width": 960,
                    "height": 720,
                    "link": "https://i.vimeocdn.com/video/514382490_960.jpg"
                  },
                  {
                    "type": "thumbnail",
                    "width": 640,
                    "height": 480,
                    "link": "https://i.vimeocdn.com/video/514382490_640.jpg"
                  },
                  {
                    "type": "thumbnail",
                    "width": 295,
                    "height": 166,
                    "link": "https://i.vimeocdn.com/video/514382490_295x166.jpg"
                  },
                  {
                    "type": "thumbnail",
                    "width": 200,
                    "height": 150,
                    "link": "https://i.vimeocdn.com/video/514382490_200x150.jpg"
                  },
                  {
                    "type": "thumbnail",
                    "width": 100,
                    "height": 75,
                    "link": "https://i.vimeocdn.com/video/514382490_100x75.jpg"
                  }
                ]
              },
              "files": [
                {
                  "quality": "sd",
                  "link": "https://player.vimeo.com/external/124597456.sd.mp4?s=837e8c77a03a46a3631372d1e67c869b&profile_id=112&oauth2_token_id=59539484",
                  "size": 300,
                  "md5": "md5hd"
                },
                {
                  "quality": "hd",
                  "link": "https://player.vimeo.com/external/124597456.hd.mp4?s=16a1712f7c756d0d8607d4081546dfdb&profile_id=113&oauth2_token_id=59539484",
                  "size": 200,
                  "md5": "md5sd"
                  },
                {
                  "quality": "hls",
                  "link": "https://player.vimeo.com/external/124597456.m3u8?p=mobile,standard,high&s=1fa307e3ac7374b93ee605e33c1cb685&oauth2_token_id=59539484",
                  "size": 100,
                  "md5": "md5hls"
                }
              ],
              "download": [
                {
                  "quality": "sd",
                  "link": "https://player.vimeo.com/external/124597456.sd.mp4?s=837e8c77a03a46a3631372d1e67c869b&profile_id=112&oauth2_token_id=59539484",
                  "size": 300
                },
                {
                  "quality": "hd",
                  "link": "https://player.vimeo.com/external/124597456.hd.mp4?s=16a1712f7c756d0d8607d4081546dfdb&profile_id=113&oauth2_token_id=59539484",
                  "size": 200
                }
              ]
            }
          ]
        }
      REQ

      class << self
        include WebMock::API

        def install
          # get list of all videos
          stub_request(:get, 'https://api.vimeo.com/me/videos')
            .with(
              query: {
                fields: %w[
                  uri
                  name
                  duration
                  width
                  height
                  status
                  modified_time
                  pictures.sizes.link
                  pictures.sizes.width
                  files.quality
                  files.size
                  files.md5
                  files.link
                  download
                ].join(',').freeze,
                sort: 'modified_time',
              }
            )
            .to_return(body: RESPONSE_LIST_1)

          # get second page of video list
          stub_request(:get, 'https://api.vimeo.com/me/videos')
            .with(
              query: {
                fields: %w[
                  uri
                  name
                  duration
                  width
                  height
                  status
                  modified_time
                  pictures.sizes.link
                  pictures.sizes.width
                  files.quality
                  files.size
                  files.md5
                  files.link
                  download
                ].join(',').freeze,
                page: '2',
                sort: 'modified_time',
              }
            )
            .to_return(body: RESPONSE_LIST_2)
        end
      end
    end
  end

  WebMock.enable!

  WebMock.disable_net_connect!(allow: /s3\.openhpicloud\.de/, allow_localhost: true, net_http_connect_on_start: true)

  XiIntegration::Video.install

  def seed!
    Video::Provider.delete_all
    provider = Video::Provider.create!(
      name: 'Gucci_Provider',
      token: '0c597a35c384f75c419634d070dd8713',
      provider_type: 'vimeo',
      credentials: {token: '0c597a35c384f75c419634d070dd8713'},
      default: true
    )
    pip_stream = Video::Stream.create!(
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
    lecturer_stream = Video::Stream.create!(
      provider_id: provider.id,
      title: 'the_course_internetworking_intro_lecturer',
      provider_video_id: '88329527',
      sd_url: 'http://player.vimeo.com/external/88329527.sd.mp4?s=b9a210b4b36ea04dc9b7eb2817f97d5a',
      width: 640, height: 360,
      poster: 'http://b.vimeocdn.com/ts/466/744/466744340_640.jpg'
    )
    slides_stream = Video::Stream.create!(
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
    video = Video::Video.create!(
      id: '00000003-3600-4444-9999-000000000001',
      title: 'WWW Introduction',
      description:,
      lecturer_stream_id: lecturer_stream.id,
      slides_stream_id: slides_stream.id
    )
    subtitle = video.subtitles.create!(lang: 'en')

    Video::SubtitleCue.create!(
      subtitle_id: subtitle.id,
      identifier: 1,
      start: 0.seconds,
      stop: 5.seconds,
      text: 'Valid interval.'
    )
    Video::SubtitleCue.create!(
      subtitle_id: subtitle.id,
      identifier: 2,
      start: 7.seconds,
      stop: 10.seconds,
      text: 'And another.'
    )
    Video::SubtitleCue.create!(
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
    Video::Video.create!(
      id: '00000003-3100-4444-9999-000000000001',
      title: 'New Video Title in open mode',
      description: 'A previewable video item',
      pip_stream_id: pip_stream.id
    )
    Video::Video.create!(
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
      Video::Video.create!(
        id:,
        title: "Video title #{i}",
        pip_stream_id: pip_stream.id
      )
    end
  end
end
