class Sonaric < Formula
  desc "Sonaric Network: the AI-powered backbone for all blockchains."
  homepage "https://sonaric.xyz"
  version "0.0.10"

  url_x64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-darwin-v0.0.10.tar.gz"
  sha256_x64 = "9b47f24704022786c0288c4b84827730d32f2ed6483834184a0de6964f1ff0cf"
  url_arm64 = "https://storage.googleapis.com/sonaric-releases/stable/macos/sonaric-arm-darwin-v0.0.10.tar.gz"
  sha256_arm64 = "ce97a5bcdacb74887dfd34fc921e785722098b1800ead578603d90f8f4687eb9"

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
