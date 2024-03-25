class Sonaric < Formula
  desc "Sonaric Network: the AI-powered backbone for all blockchains."
  homepage "https://sonaric.xyz"
  version "0.0.1"

  url_x64 = "https://storage.googleapis.com/sonaric-releases/nightly/macos/sonaric-darwin-latest.tar.gz"
  sha256_x64 = "c385ae3c5ff0814029a29e86d76d4d8292ff7026fc6d35033cb576e1461ab97d"
  url_arm64 = "https://storage.googleapis.com/sonaric-releases/nightly/macos/sonaric-arm-darwin-latest.tar.gz"
  sha256_arm64 = "24d3cd02550cc51140ec76c4ed39940f4e7d13ffe33a22c04e225dd575f562e1"

  if Hardware::CPU.intel?
    sha256 sha256_x64
    url url_x64
  else
    sha256 sha256_arm64
    url url_arm64
  end

  depends_on "podman" => :recommended

  def install
    bin.install "sonaric" => "sonaric"
    bin.install "sonaricd" => "sonaricd"
  end

  def caveats; <<~EOS
    Initialize the sonaric machine with sonaric daemon inside
      sonaric machine init

    Upgrade sonaric daemon inside the sonaric machine to the latest version
      sonaric machine upgrade
    EOS
  end
end
