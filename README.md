# Audiobook utilities Homebrew tap

Homebrew formulas for Brandon's audiobook command-line utilities:

```bash
brew tap brandonscript/tap
brew install goodscraps
brew install bookpeek
```

`goodscraps` installs its isolated Python runtime and CLI. `bookpeek` also
installs `ffmpeg`, its online providers, ASR engines, and the spaCy English
model so the command is ready to run after installation.

## Updating formulas

Update the package version, source URL, and SHA-256 in the relevant formula.
For Python packages, the source archive hash can be obtained from PyPI or the
GitHub release archive.
