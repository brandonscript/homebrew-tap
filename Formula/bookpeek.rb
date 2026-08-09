class Bookpeek < Formula
  desc "Extract audiobook metadata from spoken introductions"
  homepage "https://github.com/brandonscript/bookpeek"
  url "https://github.com/brandonscript/bookpeek/archive/refs/tags/v0.2.1.tar.gz"
  sha256 "1e262f4dfb993d5cecda7fcbc5bfd7ceafac3479abbc30be0f16422771e48ca7"
  license "MIT"

  depends_on "ffmpeg"
  depends_on "python@3.14"

  # After we rewrite PyAV /DLC/ IDs to @rpath, keep them (do not expand to Cellar paths).
  preserve_rpath

  def install
    python_formula = "python@3.14"
    python_bin = "python3.14"
    # On Apple Silicon, vosk is layered from the release wheel after the package install.
    extras = OS.mac? && Hardware::CPU.arm? ? ".[whisper,online]" : ".[whisper,vosk,online]"

    python = formula_opt_bin(python_formula)/python_bin
    venv = HOMEBREW_PREFIX/"var"/"bookpeek"/"venv"
    venv.parent.mkpath

    pip_cache = HOMEBREW_CACHE/"caches/bookpeek-pip"
    pip_cache.mkpath
    ENV["PIP_CACHE_DIR"] = pip_cache.to_s

    system python, "-m", "venv", venv unless (venv/"bin/python").exist?
    system venv/"bin/pip", "install", "--upgrade", "pip"
    system venv/"bin/pip", "install", "--upgrade", extras
    if OS.mac? && Hardware::CPU.arm?
      wheel = "https://github.com/brandonscript/bookpeek/releases/download/v#{version}/vosk-0.3.45-py3-none-macosx_11_0_arm64.whl"
      system venv/"bin/pip", "install", "--upgrade", wheel
    end
    rewrite_pyav_delocate_dylibs!(venv) if OS.mac?
    unless quiet_system venv/"bin/python", "-c", "import en_core_web_sm"
      system venv/"bin/python", "-m", "spacy", "download", "en_core_web_sm"
    end
    bin.install_symlink venv/"bin/bookpeek"
  end

  def caveats
    cache = HOMEBREW_CACHE/"caches/bookpeek-pip"
    <<~EOS
      Whisper + Vosk are installed. Dual-engine scanning is the default; pass
      --engine whisper or --engine vosk to use only one backend. ASR model
      weights download on first scan into ~/.config/bookpeek/models/ (and the
      Hugging Face cache for Whisper). Pass -d to download missing models
      without prompting.

      Pip wheel cache (speeds up reinstalls): #{cache}
      Persistent venv: #{HOMEBREW_PREFIX}/var/bookpeek/venv
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
