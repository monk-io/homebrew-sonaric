class SonaricRuntime < Formula
  desc "Sonaric Network Runtime: the AI-powered backbone for all blockchains."
  homepage "https://sonaric.xyz"
  version "0.0.1"

  depends_on "podman"

  resource "sonaric-runtime" do
    url "https://github.com/monk-io/homebrew-sonaric.git", branch: "main"
  end

  def install
    resources.each do |r|
      case r.name
      when "sonaric-runtime"
        bin.install r.cached_download/"sonaric-runtime.sh" => "sonaric-runtime"
      end
    end
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
