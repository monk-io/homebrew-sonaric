class Sonaric < Formula
  desc "Sonaric Network: the AI-powered backbone for all blockchains."
  homepage "https://sonaric.xyz"
  version "0.0.18"

  url_x64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-darwin-v0.0.18.tar.gz"
  sha256_x64 = "f2b99880e2bc5f23609225c9c3b1aeb933a108ce2fc657772e6d3d3781fb1e78"
  url_arm64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-arm-darwin-v0.0.18.tar.gz"
  sha256_arm64 = "0f9b55e6137c7e6ffe631f453f903191d6e112569ff774a49734294ea76bf613"

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
