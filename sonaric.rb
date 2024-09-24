class Sonaric < Formula
  desc "Sonaric Network: the AI-powered backbone for all blockchains."
  homepage "https://sonaric.xyz"
  version "1.7.8"

  url_x64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-darwin-v1.7.8.tar.gz"
  sha256_x64 = "8b274304c2a5217418e0abaa6da8ecebfa8c2eb9bfa8c3ee420989ed5dda0f6a"
  url_arm64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-arm-darwin-v1.7.8.tar.gz"
  sha256_arm64 = "2eb45cf0fc654094a81bd5091078d602303ee0eeda378ee3b52014e7d2c05677"

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
    url "https://raw.githubusercontent.com/monk-io/homebrew-sonaric/v1.7.8/sonaric-entrypoint.sh"
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
