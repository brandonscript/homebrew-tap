class PlexMgmt < Formula
  desc "Plex database management CLI with confirmation safeguards"
  homepage "https://github.com/brandonscript/plex-mgmt"
  url "https://github.com/brandonscript/plex-mgmt.git",
      tag:      "v0.1.0",
      revision: "06c8ce1d9ce46653a7f289cdbc3ebc89988407c6"
  depends_on "python@3.14"

  def install
    python = formula_opt_bin("python@3.14")/"python3.14"
    venv = libexec/"venv"

    system python, "-m", "venv", venv
    system venv/"bin/python", "-m", "pip", "install", "--upgrade", "pip"
    system venv/"bin/python", "-m", "pip", "install", "."
    bin.install_symlink venv/"bin/plex"
    pkgshare.install "env.example"
  end

  def caveats
    <<~EOS
      Create ~/.config/plex-mgmt/.env using #{pkgshare}/env.example as a guide.
      Set PLEX_MGMT_ENV_FILE if you keep the configuration elsewhere.
      Installing or upgrading this formula requires GitHub access to the private
      brandonscript/plex-mgmt repository.
    EOS
  end

  test do
    assert_match "Plex Management Tools", shell_output("#{bin}/plex --help")
  end
end
