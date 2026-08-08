class Goodscraps < Formula
  desc "Read-only Goodreads metadata client and CLI"
  homepage "https://github.com/brandonscript/goodscraps"
  url "https://files.pythonhosted.org/packages/ff/18/040ff203082551857e0407e921a4383d3880f3dde74d899150a630160c06/goodscraps-0.1.7.tar.gz"
  sha256 "01eb739f8dc84ff682f9abb671541f0b2b234336ef8704db8676273b41e252ae"
  license "MIT"

  depends_on "python@3.14"

  def install
    python = formula_opt_bin("python@3.14")/"python3.14"
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
