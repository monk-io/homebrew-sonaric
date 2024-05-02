class Sonaric < Formula
  desc "Sonaric Network: the AI-powered backbone for all blockchains."
  homepage "https://sonaric.xyz"
  version "0.0.21"

  url_x64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-darwin-v0.0.21.tar.gz"
  sha256_x64 = "99fc6a9cc2759f4d9a41aa873291365033976e4904cce27093940cdc6e84be2b"
  url_arm64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-arm-darwin-v0.0.21.tar.gz"
  sha256_arm64 = "210a8f361dc4a175612b8c580e07e515439134ea3368027279c05c1f189c014d"

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
