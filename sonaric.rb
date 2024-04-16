class Sonaric < Formula
  desc "Sonaric Network: the AI-powered backbone for all blockchains."
  homepage "https://sonaric.xyz"
  version "0.0.10"

  url_x64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-darwin-v0.0.10.tar.gz"
  sha256_x64 = "9b47f24704022786c0288c4b84827730d32f2ed6483834184a0de6964f1ff0cf"
  url_arm64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-arm-darwin-v0.0.10.tar.gz"
  sha256_arm64 = "ce97a5bcdacb74887dfd34fc921e785722098b1800ead578603d90f8f4687eb9"

  depends_on "podman" => :recommended

  resource "sonaric-entrypoint" do
    url "https://github.com/monk-io/homebrew-sonaric.git", branch: "main"
  end

  if Hardware::CPU.intel?
    sha256 sha256_x64
    url url_x64
  else
    sha256 sha256_arm64
    url url_arm64
  end

  def install
    resources.each do |r|
      case r.name
      when "sonaric-entrypoint"
        bin.install r.cached_download/"sonaric-entrypoint.sh" => "sonaric-entrypoint"
      end
    end
    bin.install "sonaric" => "sonaric"
    bin.install "sonaricd" => "sonaricd"
  end

  def caveats; <<~EOS
    Sonaric will be started automatically via brew services
      brew services info sonaric
    EOS
  end

  service do
    run [opt_bin/"sonaric-entrypoint"]
    keep_alive true
  end
end
