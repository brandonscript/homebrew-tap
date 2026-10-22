class NodeMash < Formula
  desc "Deduplicate dependency files with independent APFS clones"
  homepage "https://github.com/brandonscript/node-mash"
  url "https://github.com/brandonscript/node-mash/archive/aab9329af0c0e487974b50d9c0e5d3de5bdf1b1c.tar.gz"
  version "0.1.0"
  sha256 "d774655dcf1fe4b8795c6ded082c1631e9ce8c45357f6ae87b7861d35c1c7de0"
  license "MIT"
  revision 1

  depends_on :macos
  depends_on "python@3.13"

  def install
    libexec.install "node_mash.py"
    (bin/"node-mash").write <<~SH
      #!/bin/sh
      exec "#{formula_opt_bin("python@3.13")}/python3.13" "#{libexec}/node_mash.py" "$@"
    SH
    (bin/"node-mash").chmod 0755
    pkgshare.install "examples/com.node-mash.plist", "examples/service.json"
  end

  service do
    run [opt_bin/"node-mash", "service", "--once", "--config", "#{Dir.home}/.config/node-mash/service.json"]
    run_type :cron
    cron "0 4 * * *"
    run_at_load false
    log_path var/"log/node-mash.log"
    error_log_path var/"log/node-mash.error.log"
  end

  test do
    assert_match "--report-dir", shell_output("#{bin}/node-mash --help")
    modules = testpath/"project/node_modules"
    modules.mkpath
    (modules/"a.js").write "x" * 8192
    (modules/"b.js").write "x" * 8192
    config = testpath/"service.json"
    config.write JSON.generate(roots: [(testpath/"project").to_s], apply: true, report_dir: (testpath/"reports").to_s)
    output = shell_output("#{bin}/node-mash service --once --config #{config}")
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
