class Bookpeek < Formula
  desc "Extract audiobook metadata from spoken introductions"
  homepage "https://github.com/brandonscript/bookpeek"
  url "https://github.com/brandonscript/bookpeek/archive/refs/tags/v0.1.2.tar.gz"
  sha256 "14217219e61eb41f7cdaed575c37a772455e133500ebfdc1174b21f0a3828eae"
  license "MIT"

  option "with-vosk", "Also install the Vosk ASR engine (uses Python 3.13; no 3.14 wheels)"

  depends_on "ffmpeg"
  depends_on "pkgconf"
  depends_on "python@3.14" if build.without?("vosk")
  depends_on "python@3.13" if build.with?("vosk")

  # Keep @rpath install names on native wheels (ctranslate2, etc.).
  preserve_rpath

  def install
    if build.with?("vosk")
      python_formula = "python@3.13"
      python_bin = "python3.13"
      extras = ".[whisper,vosk]"
    else
      python_formula = "python@3.14"
      python_bin = "python3.14"
      extras = ".[whisper]"
    end

    python = formula_opt_bin(python_formula)/python_bin
    venv = libexec/"venv"

    # Link PyAV against Homebrew ffmpeg instead of wheel-vendored /DLC/ dylibs
    # whose short install names cannot be expanded into Cellar paths.
    ENV.append_path "PKG_CONFIG_PATH", Formula["ffmpeg"].opt_lib/"pkgconfig"
    ENV.append "LDFLAGS", "-Wl,-headerpad_max_install_names" if OS.mac?

    system python, "-m", "venv", venv
    system venv/"bin/pip", "install", "--upgrade", "pip"
    system venv/"bin/pip", "install", "--no-binary=av", extras
    system venv/"bin/python", "-m", "spacy", "download", "en_core_web_sm"
    bin.install_symlink venv/"bin/bookpeek"
  end

  def caveats
    if build.with?("vosk")
      <<~EOS
        Installed with Whisper + Vosk ASR engines (Python 3.13).
        Default engine is still whisper; select Vosk with --engine vosk.
      EOS
    else
      <<~EOS
        Installed with the Whisper ASR extra (faster-whisper; mlx-whisper on Apple Silicon).
        Vosk is opt-in (no Python 3.14 wheels):
          brew reinstall bookpeek --with-vosk
      EOS
    end
  end

  test do
    assert_match "scan", shell_output("#{bin}/bookpeek --help")
  end
end
