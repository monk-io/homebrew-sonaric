class Sonaric < Formula
  desc "Sonaric Network: the AI-powered backbone for all blockchains."
  homepage "https://sonaric.xyz"
  version "1.0.0-core.1"

  url_x64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-darwin-v1.0.0-core.1.tar.gz"
  sha256_x64 = "53db135c5e82df1031e61b359ce6ae0d374b00db762f953ff3edaf33a479c754"
  url_arm64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-arm-darwin-v1.0.0-core.1.tar.gz"
  sha256_arm64 = "a8259b06f11528d5ac9ee46221be8bd751a4619c9450a669c9668301fdd10027"

  depends_on "monk-io/sonaric/sonaric-runtime"

  if Hardware::CPU.intel?
    sha256 sha256_x64
    url url_x64
  else
    sha256 sha256_arm64
    url url_arm64
  end

  resource "sonaric-entrypoint" do
    sha256 "f03c11a3035f4a82f7974d361ebfa6591e5529e108f8acca1d97bbac85a71ee6"
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
