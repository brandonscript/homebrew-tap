class Bookpeek < Formula
  desc "Extract audiobook metadata from spoken introductions"
  homepage "https://github.com/brandonscript/bookpeek"
  url "https://github.com/brandonscript/bookpeek/archive/refs/tags/v0.1.2.tar.gz"
  sha256 "14217219e61eb41f7cdaed575c37a772455e133500ebfdc1174b21f0a3828eae"
  license "MIT"

  option "with-vosk", "Also install the Vosk ASR engine (uses Python 3.13; no 3.14 wheels)"

  depends_on "ffmpeg"
  depends_on "python@3.14" if build.without?("vosk")
  depends_on "python@3.13" if build.with?("vosk")

  # Keep @rpath install names on native wheels (ctranslate2, PyAV after rewrite, etc.).
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

    # Survive reinstalls: reuse wheels/models already downloaded under Homebrew's cache.
    pip_cache = HOMEBREW_CACHE/"caches/bookpeek-pip"
    pip_cache.mkpath
    ENV["PIP_CACHE_DIR"] = pip_cache.to_s

    system python, "-m", "venv", venv
    system venv/"bin/pip", "install", "--upgrade", "pip"
    system venv/"bin/pip", "install", extras
    rewrite_pyav_delocate_dylibs!(venv) if OS.mac?
    system venv/"bin/python", "-m", "spacy", "download", "en_core_web_sm"
    bin.install_symlink venv/"bin/bookpeek"
  end

  def caveats
    cache = HOMEBREW_CACHE/"caches/bookpeek-pip"
    engine = if build.with?("vosk")
      "Whisper + Vosk (Python 3.13). Default engine is whisper; use --engine vosk to select Vosk."
    else
      "Whisper only (faster-whisper; mlx-whisper on Apple Silicon). Opt into Vosk with: brew reinstall bookpeek --with-vosk"
    end
    <<~EOS
      #{engine}

      Pip wheel cache (speeds up reinstalls): #{cache}
      Whisper model weights download on first scan into the usual HF/cache dirs, not during brew install.
    EOS
  end

  test do
    assert_match "scan", shell_output("#{bin}/bookpeek --help")
  end

  # PyAV macOS wheels vendor dylibs with delocate placeholder IDs (/DLC/...).
  # Homebrew cannot expand those short IDs into Cellar paths (headerpad). Rewrite
  # to @rpath and rely on preserve_rpath so post-install linkage fixup is a no-op.
  def rewrite_pyav_delocate_dylibs!(venv)
    require "macho"

    Dir[venv/"lib/*/site-packages/av/**/*.{dylib,so}"].each do |file|
      next unless File.file?(file)

      chmod "u+w", file
      begin
        macho = MachO.open(file)
      rescue MachO::NotAMachOError, MachO::MachOError
        next
      end

      id = if macho.respond_to?(:machos)
        macho.machos.map(&:dylib_id).compact.find { |i| i.start_with?("/DLC/") }
      else
        macho.dylib_id
      end
      if id&.start_with?("/DLC/")
        MachO::Tools.change_dylib_id(file, "@rpath/#{File.basename(id)}")
      end

      MachO::Tools.dylibs(file).each do |dep|
        next unless dep.start_with?("/DLC/")

        MachO::Tools.change_install_name(file, dep, "@rpath/#{File.basename(dep)}")
      end

      # Ad-hoc sign after rewriting load commands (Apple Silicon).
      system "/usr/bin/codesign", "--force", "--sign", "-", file if Hardware::CPU.arm?
    end
  end
end
