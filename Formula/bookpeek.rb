class Bookpeek < Formula
  desc "Extract audiobook metadata from spoken introductions"
  homepage "https://github.com/brandonscript/bookpeek"
  url "https://github.com/brandonscript/bookpeek/archive/refs/tags/v0.1.3.tar.gz"
  sha256 "e41f48f1cbcdd2a55982e598c157603d04b6c11ac0c3f05b4ca23c962b6b80b8"
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

  # PyAV macOS wheels vendor dylibs under a HIDDEN .dylibs/ dir with /DLC/...
  # placeholder IDs. Dir.glob skips dotdirs unless we name them explicitly.
  # Rewrite to @rpath so Homebrew's linkage fixer (preserve_rpath) leaves them alone.
  def rewrite_pyav_delocate_dylibs!(venv)
    dylib_dirs = Dir.glob("#{venv}/lib/*/site-packages/av/.dylibs")
    odie "PyAV .dylibs not found under #{venv}" if dylib_dirs.empty?

    install_name_tool = Utils.safe_popen_read("xcrun", "--find", "install_name_tool").strip
    otool = Utils.safe_popen_read("xcrun", "--find", "otool").strip
    codesign = "/usr/bin/codesign"

    files = dylib_dirs.flat_map { |dir| Dir.glob("#{dir}/*.dylib") }
                      .select { |f| File.file?(f) && !File.symlink?(f) }
    # Also fix extension modules that may reference /DLC/ deps.
    files += Dir.glob("#{venv}/lib/*/site-packages/av/**/*.so")
                .select { |f| File.file?(f) && !File.symlink?(f) }

    ohai "Rewriting #{files.count { |f| dylib_id_for(otool, f)&.start_with?("/DLC/") }} PyAV /DLC/ install names"

    files.each do |file|
      changed = false

      id = dylib_id_for(otool, file)
      if id&.start_with?("/DLC/")
        File.chmod(File.stat(file).mode | 0200, file)
        odie "install_name_tool -id failed: #{file}" unless quiet_system install_name_tool, "-id", "@rpath/#{File.basename(id)}", file
        changed = true
      end

      dylib_deps_for(otool, file).each do |dep|
        next unless dep.start_with?("/DLC/")

        File.chmod(File.stat(file).mode | 0200, file)
        odie "install_name_tool -change failed: #{file}" unless quiet_system install_name_tool, "-change", dep, "@rpath/#{File.basename(dep)}", file
        changed = true
      end

      next unless changed && Hardware::CPU.arm?

      odie "codesign failed: #{file}" unless quiet_system codesign, "--force", "--sign", "-", file
    end

    leftover = dylib_dirs.flat_map { |dir| Dir.glob("#{dir}/*.dylib") }
                         .select { |f| dylib_id_for(otool, f)&.start_with?("/DLC/") }
    return if leftover.empty?

    odie <<~EOS
      Failed to clear PyAV /DLC/ dylib IDs (Homebrew linkage fixer will fail):
        #{leftover.join("\n  ")}
    EOS
  end

  def dylib_id_for(otool, file)
    lines = Utils.safe_popen_read(otool, "-D", file).lines.map(&:strip).reject(&:empty?)
    lines.last
  rescue
    nil
  end

  def dylib_deps_for(otool, file)
    Utils.safe_popen_read(otool, "-L", file)
         .lines
         .drop(1)
         .filter_map { |line| line.strip.split.first }
  rescue
    []
  end
end
