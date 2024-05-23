class SonaricRuntime < Formula
  desc "Sonaric Network Runtime: the AI-powered backbone for all blockchains."
  homepage "https://sonaric.xyz"
  version "0.0.1"

  depends_on "podman"
  url "https://github.com/monk-io/homebrew-sonaric.git", branch: "main"

  def install
    bin.install "sonaric-runtime.sh" => "sonaric-runtime"
  end

  def caveats; <<~EOS
    Sonaric runtime will be started automatically via brew services
      brew services info sonaric-runtime
    EOS
  end

  service do
    run [opt_bin/"sonaric-runtime"]
    keep_alive true
  end
end
