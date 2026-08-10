class Fixm4b < Formula
  desc "Retag converted audiobooks (ID3 / filenames) without re-encoding"
  homepage "https://github.com/brandonscript/fixm4b"
  url "https://files.pythonhosted.org/packages/87/8b/99322ffdabefd0c9e8c80f256cebf2ea721245beccf75a41656ab69d019d/fixm4b-0.1.4.tar.gz"
  sha256 "7a7572934ca6d3247e2025349082b845210cd1df7c5bff7e8b0a5b9ef46decd9"
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
