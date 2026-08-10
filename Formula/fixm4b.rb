class Fixm4b < Formula
  desc "Retag converted audiobooks (ID3 / filenames) without re-encoding"
  homepage "https://github.com/brandonscript/fixm4b"
  url "https://files.pythonhosted.org/packages/5f/b1/affa6fffaa251a17c30f84e3a958f5a511f229f9ac61bdbc6bdaa286cc61/fixm4b-0.1.3.tar.gz"
  sha256 "a030bad11add5008f0453ec53987a19a6b9fe00f7b939a3710552acd6edced85"
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
