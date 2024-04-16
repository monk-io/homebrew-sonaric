class Sonaric < Formula
  desc "Sonaric Network: the AI-powered backbone for all blockchains."
  homepage "https://sonaric.xyz"
  version "0.0.11"

  url_x64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-darwin-v0.0.11.tar.gz"
  sha256_x64 = "1a586d718104fb2db34d237f8303586c569e4ccb617647dfe2d82c769ec31791"
  url_arm64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-arm-darwin-v0.0.11.tar.gz"
  sha256_arm64 = "d5b4c5fb61e9848453866a4404a162956ebb4421d3ce9ffd79cabe420eb9e574"

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
