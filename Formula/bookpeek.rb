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

  # After we rewrite PyAV /DLC/ IDs to @rpath, keep them (do not expand to Cellar paths).
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
  # Homebrew cannot expand those into Cellar paths. Rewrite to @rpath quietly;
  # preserve_rpath makes the post-install linkage fixer leave them alone.
  def rewrite_pyav_delocate_dylibs!(venv)
    files = Dir.glob("#{venv}/lib/*/site-packages/av/**/*.{dylib,so}").select do |f|
      File.file?(f) && !File.symlink?(f)
    end
    return if files.empty?

    files.each do |file|
      changed = false

      id = dylib_id_for(file)
      if id&.start_with?("/DLC/")
        chmod "u+w", file
        unless quiet_system "/usr/bin/install_name_tool", "-id", "@rpath/#{File.basename(id)}", file
          odie "install_name_tool -id failed for #{file}"
        end
        changed = true
      end

      dylib_deps_for(file).each do |dep|
        next unless dep.start_with?("/DLC/")

        chmod "u+w", file
        unless quiet_system "/usr/bin/install_name_tool", "-change", dep, "@rpath/#{File.basename(dep)}", file
          odie "install_name_tool -change failed for #{file} (#{dep})"
        end
        changed = true
      end

      next unless changed && Hardware::CPU.arm?

      # Ad-hoc sign only when we rewrote load commands; stay quiet (no ==> spew).
      unless quiet_system "/usr/bin/codesign", "--force", "--sign", "-", file
        odie "codesign failed for #{file}"
      end
    end

    leftover = files.select { |f| dylib_id_for(f)&.start_with?("/DLC/") }
    return if leftover.empty?

    odie <<~EOS
      Failed to clear PyAV /DLC/ dylib IDs (Homebrew linkage fixer will fail):
        #{leftover.join("\n  ")}
    EOS
  end

  def dylib_id_for(file)
    # otool -D prints the path, then the id.
    lines = Utils.safe_popen_read("/usr/bin/otool", "-D", file).lines.map(&:strip).reject(&:empty?)
    lines.last
  rescue
    nil
  end

  def dylib_deps_for(file)
    # First line is the file header; remaining lines are "name (compatibility ...)".
    Utils.safe_popen_read("/usr/bin/otool", "-L", file)
         .lines
         .drop(1)
         .filter_map { |line| line.strip.split.first }
  rescue
    []
  end
end
