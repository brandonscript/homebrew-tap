class Dnspoke < Formula
  desc "Invite-scoped dynamic DNS updates with short-lived tokens"
  homepage "https://github.com/brandonscript/dnspoke"
  url "https://github.com/brandonscript/dnspoke/archive/refs/tags/v0.1.5.tar.gz"
  sha256 "e9f806ec0224f68539d5c7cd034d61a1785a33967759a1def0b0b8f40388683b"
  license "MIT"
  depends_on "python@3.14"

  def install
    libexec.install "dnspoke"
    (bin/"dnspoke").write <<~SH
      #!/bin/sh
      PYTHONPATH="#{libexec}" exec "#{formula_opt_bin("python@3.14")}/python3.14" -m dnspoke.cli "$@"
    SH
  end

  service do
    run [opt_bin/"dnspoke", "watch"]
    keep_alive true
    log_path var/"log/dnspoke.log"
    error_log_path var/"log/dnspoke.log"
  end

  def caveats
    <<~EOS
      Enroll using the invite supplied by your administrator:
        dnspoke enroll
        dnspoke update
      The invite includes the server address. Paste it at the visible prompt.
      Set a check period in minutes (optional; default 5):
        dnspoke configure --ttl 15
      Then enable background updates:
        brew services start dnspoke
      Stop background updates:
        brew services stop dnspoke
      Credentials are stored in ~/.config/dnspoke/device.json (mode 600).
      Run services as your user, without sudo, so they use your enrollment.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/dnspoke --version")
    assert_match "enroll", shell_output("#{bin}/dnspoke --help")
    assert_match "invite", shell_output("#{bin}/dnspoke admin --help")
  end
end
