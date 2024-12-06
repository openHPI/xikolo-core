# Visualize Git History/Changes

Use [`gource`](https://github.com/acaudwell/Gource) to visualize Git history and optionally safe it as a raw video for further processing. Gource is available in Debian software repository.

```console
gource \
  --start-date 2020-01-01 \
  --stop-date 2021-01-01 \
  --git-branch master \
  --key \
  --elasticity 0.0001 \
  --dir-font-size 10 \
  --file-font-size 10 \
  --user-font-size 10 \
  --font-file /usr/share/fonts/truetype/roboto/unhinted/RobotoTTF/Roboto-Regular.ttf \
  --user-image-dir .git/avatars/ \
  --max-file-lag 1 \
  --multi-sampling \
  --viewport 1920x1080 \
  --seconds-per-day 1.35
```

See `man gource` too.

To additionally render into a video, add a few more parameters to `gource` and pipe additional output to `ffmpeg`. See [wiki](https://github.com/acaudwell/Gource/wiki/Videos) too.

```console
...
  --disable-input \
  --output-framerate 30 \
  --output-ppm-stream - \
  | ffmpeg -y -r 30 -f image2pipe -vcodec ppm -i - -b 65536K output.mp4
```

This source video can be further edited e.g. by adding fade-in-out, music and an intro. The `seconds-per-day` option can be adjusted to make the video short or longer, e.g. to match a specific music piece, but it probably shouldn't be less than a second.
