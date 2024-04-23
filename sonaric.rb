class Sonaric < Formula
  desc "Sonaric Network: the AI-powered backbone for all blockchains."
  homepage "https://sonaric.xyz"
  version "0.0.17"

  url_x64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-darwin-v0.0.17.tar.gz"
  sha256_x64 = "593b9df7c114d20d46b04adba5c0dd9fe4ac3194155a915f9a7e41aa8cc425e7"
  url_arm64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-arm-darwin-v0.0.17.tar.gz"
  sha256_arm64 = "7521b1eeb507bcfebb16f702970eb3da6545b59322266a5ace0ca171580cf97b"

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
