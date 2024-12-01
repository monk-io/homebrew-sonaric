class Sonaric < Formula
  desc "Sonaric Network: the AI-powered backbone for all blockchains."
  homepage "https://sonaric.xyz"
  version "1.9.4"

  url_x64 = "https://get.sonaric.xyz/stable/macos/sonaric-darwin-v1.9.4.tar.gz"
  sha256_x64 = "d42196fe2ea54d5d2192944a9c1543f3c58cc8cb892848e01fd1aa622fad659f"
  url_arm64 = "https://get.sonaric.xyz/stable/macos/sonaric-arm-darwin-v1.9.4.tar.gz"
  sha256_arm64 = "981403e492592fa998c2a4b4b6c69c08f09c09de4236903986bc05bc361a8afa"

  depends_on "monk-io/sonaric/sonaric-runtime"

  if Hardware::CPU.intel?
    sha256 sha256_x64
    url url_x64
  else
    sha256 sha256_arm64
    url url_arm64
  end

  resource "sonaric-entrypoint" do
    sha256 "3e891bbc3b4f02d836ea44d9e5dd347de87ba129c3a82991064c9ea4b674da11"
    url "https://raw.githubusercontent.com/monk-io/homebrew-sonaric/v1.9.4/sonaric-entrypoint.sh"
  end

  def install
    bin.install "sonaric" => "sonaric"
    bin.install "sonaricd" => "sonaricd"

    resources.each do |r|
      case r.name
      when "sonaric-entrypoint"
        bin.install r.cached_download => "sonaric-entrypoint"
      end
    end
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
