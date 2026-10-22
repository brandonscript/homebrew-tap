class NodeMash < Formula
  desc "Deduplicate dependency files with independent APFS clones"
  homepage "https://github.com/brandonscript/node-mash"
  url "https://github.com/brandonscript/node-mash/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "09d71d14736eb80e6d8a82065e1dbc08f1b478a16bea5c739119d364cc1a3481"
  license "MIT"

  depends_on :macos
  depends_on "python@3.13"

  def install
    libexec.install "node_mash.py"
    (bin/"node-mash").write <<~SH
      #!/bin/sh
      exec "#{formula_opt_bin("python@3.13")}/python3.13" "#{libexec}/node_mash.py" "$@"
    SH
    (bin/"node-mash").chmod 0755
    pkgshare.install "examples/com.node-mash.plist"
  end

  test do
    assert_match "--report-dir", shell_output("#{bin}/node-mash --help")
    modules = testpath/"project/node_modules"
    modules.mkpath
    (modules/"a.js").write "x" * 8192
    (modules/"b.js").write "x" * 8192
    output = shell_output("#{bin}/node-mash dedupe #{testpath}/project --apply --report-dir #{testpath}/reports")
    report = JSON.parse(output)
    assert_equal "completed", report.fetch("status")
    action = report.fetch("actions").fetch(0)
    assert action.fetch("verified")
    source = Pathname(action.fetch("source"))
    target = Pathname(action.fetch("path"))
    refute_equal source.stat.ino, target.stat.ino
    File.write(target, "changed")
    assert_equal "x" * 8192, source.read
    assert_equal 1, (testpath/"reports").glob("*.json").length
  end
end
