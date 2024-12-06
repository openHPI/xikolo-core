# Local setup on Apple Silicon

Since the arrival of the Apple Silicon M1 chip, you must fulfill an additional prerequisite if you use that platform. There are ruby gems that cannot build natively on this architecture. Fortunately, there is an easy solution. Basically, you run the whole local setup on a Terminal in "Rosetta Mode".

## How to use Rosetta

Rosetta is a dynamic binary translator developed by Apple. Basically, you run the app like on an Intel architecture.

Fun fact: it is named after the [Rosetta Stone](https://en.wikipedia.org/wiki/Rosetta_(software)), the artifact which enabled the translation of Egyptian hieroglyphs.

## Setup

The setup guide is based on [this source](https://github.com/rcairo/rcairo/issues/49).

- Open the Terminal app.
- Open the Terminal app’s Preferences.
- Click on the Profiles tab.
- Select a profile, click on the ellipsis at the bottom of the profile list and then select *Duplicate Profile*.
- Click on the new profile and give it a good name. I named mine as `Rosetta Shell`.
- Also in the new profile, click on the *Window* tab. In the *Title*, put a name to indicate that this is for running Intel-based apps. I put `Terminal (Intel)` on mine.
- Click on the *Shell* tab and use the following as its *Run Command* to force the shell run under Rosetta:

  ```console
  env /usr/bin/arch -x86_64 /bin/zsh --login
  ```

- Untick the *Run inside shell checkbox*. Clearing the checkbox would prevent running the shell twice, which could bloat your environment variables since `~/.zshrc` gets run twice.
- Optionally set this profile as the Default.

You can also duplicate the terminal app and rename it e.g. `Rosetta Terminal`.

## Other M1 oddities

### Cairo gem

We still found one gem that did not build via bundle install. If you find the error:

```text
Installing cairo 1.16.5 with native extensions E> Gem::Ext::BuildError: ERROR: Failed to build gem native extension.
```

You can manually install [this workaround](https://github.com/rcairo/rcairo/issues/49):

```console
gem install pkg-config
```
