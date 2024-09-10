class Sonaric < Formula
  desc "Sonaric Network: the AI-powered backbone for all blockchains."
  homepage "https://sonaric.xyz"
  version "1.7.4"

  url_x64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-darwin-v1.7.4.tar.gz"
  sha256_x64 = "9b929c70f03b111ac19766e859c7e9dd7cc7410be4f80524b8c8cc1b2694ecf7"
  url_arm64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-arm-darwin-v1.7.4.tar.gz"
  sha256_arm64 = "ac2723515fb39921a10948f93466b7a614f801a718070f45e483ab8063474d3a"

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
    url "https://raw.githubusercontent.com/monk-io/homebrew-sonaric/v1.7.4/sonaric-entrypoint.sh"
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
