class Shrinx < Formula
  desc "Shrink images to WebP with verified metadata handling and scheduled cleanup"
  homepage "https://github.com/brandonscript/shrinx"
  url "https://github.com/brandonscript/shrinx/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "d89aa0da6e7b954767d4041b60f2f667c99aa25c430e4cf157bf441382e330d2"
  license "MIT"

  depends_on "exiftool"
  depends_on :macos
  depends_on "python@3.13"
  depends_on "webp"

  def install
    libexec.install "shrinx.py", "metadata.py", "png_colors.py"
    pkgshare.install "config.example.json"
    (bin/"shrinx").write <<~SH
      #!/bin/bash
      export SHRINX_SCRIPT="#{opt_libexec}/shrinx.py"
      export SHRINX_PYTHON="#{formula_opt_bin("python@3.13")}/python3.13"
      export SHRINX_CONFIG="${SHRINX_CONFIG:-$HOME/.config/shrinx/config.json}"
      export PATH="#{formula_opt_bin("webp")}:#{formula_opt_bin("exiftool")}:$PATH"
      exec "$SHRINX_PYTHON" "$SHRINX_SCRIPT" "$@"
    SH
    chmod 0755, bin/"shrinx"
  end

  def caveats
    <<~EOS
      On first setup, create your personal configuration:
        mkdir -p ~/.config/shrinx
        cp #{opt_prefix}/share/shrinx/config.example.json ~/.config/shrinx/config.json

      Keep your existing config when upgrading. Edit the folders/settings, then:
        shrinx run --dry-run
        shrinx run
        shrinx install

      Installation does not start conversion or register a schedule.
      Use `shrinx install`, not `brew services`, for the configured daily schedule.
      Before removing the package, run `shrinx uninstall` to remove that schedule.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/shrinx --version")
    assert_match "--config", shell_output("#{bin}/shrinx --help")
    python = formula_opt_bin("python@3.13")/"python3.13"
    system python, "-c", <<~PYTHON
      import json, struct, zlib
      from pathlib import Path
      def chunk(kind, data):
          return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
      png = (b'\\x89PNG\\r\\n\\x1a\\n'
          + chunk(b'IHDR', struct.pack('>IIBBBBB', 16, 16, 8, 2, 0, 0, 0))
          + chunk(b'IDAT', zlib.compress((b'\\0' + bytes([23, 123, 234]) * 16) * 16))
          + chunk(b'IEND', b''))
      Path('sample.png').write_bytes(png)
      cfg = json.loads(Path('#{pkgshare}/config.example.json').read_text())
      cfg.update(folders=[str(Path.cwd())], reports_directory=str(Path.cwd() / 'reports'),
                 minimum_age_seconds=0, only_if_smaller=False)
      cfg['file_types'] = {'png': {'enabled': True, 'mode': 'lossless'}}
      Path('config.json').write_text(json.dumps(cfg))
    PYTHON
    system bin/"shrinx", "--config", testpath/"config.json", "run"
    assert_path_exists testpath/"sample.webp"
    assert_path_exists testpath/"sample.png"
    assert_equal 1, (testpath/"reports").glob("run-*.json").length
    system formula_opt_bin("webp")/"dwebp", "-quiet", testpath/"sample.webp", "-o", File::NULL
  end
end
