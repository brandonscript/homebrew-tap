class Goodscraps < Formula
  desc "Read-only Goodreads metadata client and CLI"
  homepage "https://github.com/brandonscript/goodscraps"
  url "https://files.pythonhosted.org/packages/6d/f1/850f57f280e1c2201d935763e3b9313d41dba4cc7bd6cc81884002b3e486/goodscraps-0.1.6.tar.gz"
  sha256 "1425351a470d4eb5a73f5852b4ec4875f481ee83b2a5f41361d0874d9067cab8"
  license "MIT"

  depends_on "python@3.13"

  def install
    python = formula_opt_bin("python@3.13")/"python3.13"
    venv = libexec/"venv"

    system python, "-m", "venv", venv
    system venv/"bin/pip", "install", "--upgrade", "pip"
    system venv/"bin/pip", "install", "."
    bin.install_symlink venv/"bin/goodscraps"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/goodscraps --version")
  end
end
