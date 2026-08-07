# Audiobook utilities Homebrew tap

Homebrew formulas for audiobook management utilities

```bash
brew tap brandonscript/tap
brew install goodscraps
brew install bookpeek
```

`goodscraps` / `fixm4b` install an isolated Python runtime and CLI.

`bookpeek` installs `ffmpeg`, Whisper ASR extras, and the spaCy English model
by default:

```bash
brew install bookpeek
```

Vosk is optional (Homebrew option; uses Python 3.13 because Vosk has no 3.14 wheels):

```bash
brew install bookpeek --with-vosk
# or
brew reinstall bookpeek --with-vosk
```

## Updating formulas

Update the package version, source URL, and SHA-256 in the relevant formula.
For Python packages, the source archive hash can be obtained from PyPI or the
GitHub release archive.

## Bookpeek install speed

The formula installs Whisper extras as binary wheels and keeps a pip cache under
Homebrew's cache directory (`$(brew --cache)/caches/bookpeek-pip`), so
`brew reinstall bookpeek` reuses large wheels (ctranslate2, etc.) instead of
re-downloading them.

Whisper **model weights** are not fetched at install time — they download on
first `bookpeek scan` into the normal Hugging Face / mlx cache locations.

