class Sonaric < Formula
  desc "Sonaric Network: the AI-powered backbone for all blockchains."
  homepage "https://sonaric.xyz"
  version "0.1.4"

  url_x64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-darwin-v0.1.4.tar.gz"
  sha256_x64 = "bf34e7db0b2bac466c57d7ee11335668f61f58d2e337b3b2105690e0d9659dc0"
  url_arm64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-arm-darwin-v0.1.4.tar.gz"
  sha256_arm64 = "e8fae11043e904c7b67c738446d8ae81c58ad928006e5ec4f720db0f0b1d01ff"

  depends_on "monk-io/sonaric/sonaric-runtime"

  if Hardware::CPU.intel?
    sha256 sha256_x64
    url url_x64
  else
    sha256 sha256_arm64
    url url_arm64
  end

  resource "sonaric-entrypoint" do
    sha256 "db76d91e488f2285f4a4bbab75523677d3c34ea6c28ae0dfe99e44e31aeccd66"
    url "https://raw.githubusercontent.com/monk-io/homebrew-sonaric/HEAD/sonaric-entrypoint.sh"
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
