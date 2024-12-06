# Install Overmind for Linux

Overmind works with [tmux](https://github.com/tmux/tmux/wiki), so you need to install it first:

```bash
sudo apt-get install tmux
```

See the [list of recent releases](https://github.com/DarthSim/overmind/releases) and pick the latest one.

Install it to `/usr/local/bin`:

1. Download linux-amd64.gz (e.g. [overmind-v2.2.0-linux-amd64.gz](https://github.com/DarthSim/overmind/releases/download/v2.2.0/overmind-v2.2.0-linux-amd64.gz))
2. Decompile the gzip file (`gunzip < overmind-v2.2.0-linux-amd64.gz > overmind`)
3. Move it to `/usr/local/bin`
4. Make it executable: `chmod +x /usr/local/bin/overmind`
