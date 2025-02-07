# frozen_string_literal: true

if Rails.env.integration?
  require 'webmock'

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
end
