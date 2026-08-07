class Bookpeek < Formula
  desc "Extract audiobook metadata from spoken introductions"
  homepage "https://github.com/brandonscript/bookpeek"
  url "https://github.com/brandonscript/bookpeek/archive/refs/tags/v0.1.2.tar.gz"
  sha256 "14217219e61eb41f7cdaed575c37a772455e133500ebfdc1174b21f0a3828eae"
  license "MIT"

  depends_on "ffmpeg"
  depends_on "python@3.14"

  def install
    python = formula_opt_bin("python@3.14")/"python3.14"
    venv = libexec/"venv"

    system python, "-m", "venv", venv
    system venv/"bin/pip", "install", "--upgrade", "pip"
    system venv/"bin/pip", "install", ".[all]"
    system venv/"bin/python", "-m", "spacy", "download", "en_core_web_sm"
    bin.install_symlink venv/"bin/bookpeek"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/bookpeek --version")
  end
end
