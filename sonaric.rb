class Sonaric < Formula
  desc "Sonaric Network: the AI-powered backbone for all blockchains."
  homepage "https://sonaric.xyz"
  version "0.0.4"

  url_x64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-darwin-v0.0.4.tar.gz"
  sha256_x64 = "4fdc9ce3008b5b2c9907eb12e9b8bc55d6982ef09380c124d3e36c9c8aa94c79"
  url_arm64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-arm-darwin-v0.0.4.tar.gz"
  sha256_arm64 = "a1237ae4567d322e11b0bc615a733108599c71bb7f2b2eb30c0e7a2bea8ea064"

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
