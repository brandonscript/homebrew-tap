class Fixm4b < Formula
  desc "Retag converted audiobooks (ID3 / filenames) without re-encoding"
  homepage "https://github.com/brandonscript/fixm4b"
  url "https://github.com/brandonscript/fixm4b/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "7a7f6b665bfe1a9d1ba542f05ffa56922beaad23e4b043674537b3d74bda7ee7"
  license "MIT"

  depends_on "python@3.14"

  def install
    python = formula_opt_bin("python@3.14")/"python3.14"
    venv = libexec/"venv"

    system python, "-m", "venv", venv
    system venv/"bin/pip", "install", "--upgrade", "pip"
    system venv/"bin/pip", "install", "."
    bin.install_symlink venv/"bin/fixm4b"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/fixm4b --version")
  end
end
