class Fixm4b < Formula
  desc "Retag converted audiobooks (ID3 / filenames) without re-encoding"
  homepage "https://github.com/brandonscript/fixm4b"
  url "https://files.pythonhosted.org/packages/d5/c3/c7bdc80cd55bef0abc111d7d1a632585973e3972f015d75063802e26c2b8/fixm4b-0.1.2.tar.gz"
  sha256 "7bfd587a88e7fdbef34dba4311b4b6063f50aa2805ddc0cab20395e52c54e05f"
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
