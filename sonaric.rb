class Sonaric < Formula
  desc "Sonaric Network: the AI-powered backbone for all blockchains."
  homepage "https://sonaric.xyz"
  version "1.9.6"

  url_x64 = "https://get.sonaric.xyz/stable/macos/sonaric-darwin-v1.9.6.tar.gz"
  sha256_x64 = "7e2ccb605c629421be01fce8339606c5a6e44a37fdf5364de89985d06ca8dc01"
  url_arm64 = "https://get.sonaric.xyz/stable/macos/sonaric-arm-darwin-v1.9.6.tar.gz"
  sha256_arm64 = "4d687a160261dd9b7e5c67f29fb1cac5c76f8d63c1aeea13bfb9c519447abe93"

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
    url "https://raw.githubusercontent.com/monk-io/homebrew-sonaric/v1.9.6/sonaric-entrypoint.sh"
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
