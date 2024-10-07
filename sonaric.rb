class Sonaric < Formula
  desc "Sonaric Network: the AI-powered backbone for all blockchains."
  homepage "https://sonaric.xyz"
  version "1.8.0"

  url_x64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-darwin-v1.8.0.tar.gz"
  sha256_x64 = "0d73a946ad1f41dedc931127f2250e51b9dd0ed4c44e43d9909375de56bb4e72"
  url_arm64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-arm-darwin-v1.8.0.tar.gz"
  sha256_arm64 = "f670fb9ce5bf251b914508f53ba42ac9ce2a38ea1d8fdae380e363f4b39fa32a"

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
    url "https://raw.githubusercontent.com/monk-io/homebrew-sonaric/v1.8.0/sonaric-entrypoint.sh"
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
