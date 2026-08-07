class Bookpeek < Formula
  desc "Extract audiobook metadata from spoken introductions"
  homepage "https://github.com/brandonscript/bookpeek"
  url "https://github.com/brandonscript/bookpeek/archive/refs/tags/v0.1.2.tar.gz"
  sha256 "14217219e61eb41f7cdaed575c37a772455e133500ebfdc1174b21f0a3828eae"
  license "MIT"

  depends_on "ffmpeg"
  depends_on "pkgconf"
  depends_on "python@3.14"

  # Keep @rpath install names on native wheels (ctranslate2, etc.).
  preserve_rpath

  def install
    python = formula_opt_bin("python@3.14")/"python3.14"
    venv = libexec/"venv"

    # Link PyAV against Homebrew ffmpeg instead of wheel-vendored /DLC/ dylibs
    # whose short install names cannot be expanded into Cellar paths.
    ENV.append_path "PKG_CONFIG_PATH", Formula["ffmpeg"].opt_lib/"pkgconfig"
    ENV.append "LDFLAGS", "-Wl,-headerpad_max_install_names" if OS.mac?

    system python, "-m", "venv", venv
    system venv/"bin/pip", "install", "--upgrade", "pip"
    system venv/"bin/pip", "install", "--no-binary=av", ".[whisper]"
    system venv/"bin/python", "-m", "spacy", "download", "en_core_web_sm"
    bin.install_symlink venv/"bin/bookpeek"
  end

  def caveats
    <<~EOS
      Installed with the Whisper ASR extra (faster-whisper; mlx-whisper on Apple Silicon).
      Vosk is omitted: it has no Python 3.14 wheels yet. For Vosk, use a 3.12/3.13 venv:
        pip install 'bookpeek[vosk]'
    EOS
  end

  test do
    assert_match "scan", shell_output("#{bin}/bookpeek --help")
  end
end
