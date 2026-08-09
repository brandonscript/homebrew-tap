# Audiobook utilities Homebrew tap

Homebrew formulas for audiobook management utilities

```bash
brew tap brandonscript/tap
brew install goodscraps
brew install bookpeek
```

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
