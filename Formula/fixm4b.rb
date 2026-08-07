class Fixm4b < Formula
  desc "Retag converted audiobooks (ID3 / filenames) without re-encoding"
  homepage "https://github.com/brandonscript/fixm4b"
  url "https://files.pythonhosted.org/packages/85/80/c386c826dfe6140e7edf463394c1678ebcd415bd5d4183c2774250e5d2fb/fixm4b-0.1.1.tar.gz"
  sha256 "308c1c618f236c5dd67992f516a7268096de19e2032055ec13c573d6de42dae2"
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
