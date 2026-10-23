# BrandonScript Homebrew tap

Homebrew formulas for image and audiobook utilities

```bash
brew tap brandonscript/tap
brew install goodscraps
brew install bookpeek
```

`plex-mgmt` is available from this public tap, but its source repository is
private. Before installing, configure GitHub authentication for the private
repository as described in [Homebrew's private Git source instructions](https://docs.brew.sh/FAQ#how-do-i-authenticate-private-git-source-downloads):

```bash
brew install brandonscript/tap/plex-mgmt
```

Copy the installed `env.example` shown by `brew info plex-mgmt` to
`~/.config/plex-mgmt/.env` and fill in your own Plex connection details.
The tap and package do not contain Plex credentials.

`goodscraps` / `fixm4b` install an isolated Python runtime and CLI.

`bookpeek` installs `ffmpeg`, Whisper + Vosk ASR packages, online enrichment,
and the spaCy English model:

```bash
brew install bookpeek
```

ASR **model weights** are not fetched at install time. On first
`bookpeek scan`, bookpeek prompts to download them (or pass `-d`). Vosk models
are stored under `~/.config/bookpeek/models/`.

On Apple Silicon, Vosk is installed from the matching bookpeek GitHub Release
wheel.

## Updating formulas

Update the package version, source URL, and SHA-256 in the relevant formula.
For Python packages, the source archive hash can be obtained from PyPI or the
GitHub release archive.

## Bookpeek install speed

The formula installs ASR extras as binary wheels and keeps a pip cache under
Homebrew's cache directory (`$(brew --cache)/caches/bookpeek-pip`), so
`brew reinstall bookpeek` reuses large wheels (ctranslate2, etc.) instead of
re-downloading them. The bookpeek venv persists under
`$(brew --prefix)/var/bookpeek/venv`.

## Shrinx

Convert PNG/JPEG/TIFF/BMP images to smaller WebP files, with metadata handling,
per-type compression settings, optional verified Trash cleanup, and run reports.

```sh
brew install brandonscript/tap/shrinx
mkdir -p ~/.config/shrinx
cp "$(brew --prefix shrinx)/share/shrinx/config.example.json" ~/.config/shrinx/config.json
shrinx run --dry-run
```

Copy the example only on first setup, then edit your folders and settings.
Use `brew services start shrinx` for its configured schedule (daily at 1 am by default),
and `brew services stop shrinx` before removing the package. Use
`shrinx schedule-once --at YYYY-MM-DDTHH:MM` for a single later run. Installing or upgrading
with Homebrew does not automatically start conversions or enable the schedule.
See the [Shrinx README](https://github.com/brandonscript/shrinx#readme)
for metadata exemptions, relative compression, and configuration details.
